class Sales < AppController

  get '/make_sale' do
    order = Order.new.create_or_load(Order::SALE)
    cart = order.items_as_cart.order(:p_name).all
    amount = cart.map{ |line_item| line_item.i_price*line_item[:qty]}.inject(0, :+)
    count = cart.map{ |line_item| line_item[:qty]}.inject(0, :+)
    title = t.sales.make_sale.title(order.o_id, order.o_code_with_dash, count, Utils::money_format(amount, 2, "$ 0")).to_s
    slim :make_sale, layout: :layout_sales, locals: {sec_nav: :nav_sales_actions, title: title, order: order, cart: cart}
  end

  post '/make_sale/add_item' do
    i_id = params[:i_id].to_s.strip
    order = Order.new.create_or_load(Order::SALE)
    item = Item.new.get_for_sale i_id, order.o_id
    if item.errors.count > 0
      message = item.errors.to_a.flatten.join(": ")
      ActionsLog.new.set(msg: message, u_id: current_user_id, l_id: current_location[:name], lvl: ActionsLog::ERROR, o_id: order.o_id, p_id: item.p_id, i_id: item.i_id).save
      flash[:error] = item.errors
    else
      added_msg = order.add_item item
      changed_msg = item.change_status Item::ON_CART, order.o_id
      flash[:notice] = [added_msg, changed_msg]
    end
    redirect to('/make_sale')
  end

  route :get, :post, '/make_sale/remove_item' do
    order = Order.new.create_or_load(Order::SALE)
    if params[:id].nil?
      slim :remove_item, layout: :layout_sales, locals: {action_url: "/make_sale/remove_item", title: t.sales.make_sale.remove_item}
    else
      item = get_item_for_removal params[:id], order
      redirect_if_has_errors item, "/make_sale"
      remove_item_from_order order, item
      redirect to "/make_sale"
    end
  end

  post '/make_sale/add_credit_note' do
    sale_order = Order.new.create_or_load(Order::SALE)
    o_code = params[:o_code].to_s.strip
    credit_order = Order.new.get_orders_with_type_status_and_code(Order::CREDIT_NOTE, Order::OPEN, o_code)
    if credit_order.errors.size > 0
      flash[:error] = credit_order.errors.to_a.flatten.join(": ") if credit_order.errors.size > 0
    else
      begin
        DB.transaction do
          Line_payment.new.set_all(o_id: sale_order.o_id, payment_type: Line_payment::CREDIT_NOTE, payment_code: credit_order.o_code, payment_ammount: credit_order.credit_total).save
          credit_order.change_status Order::USED
          credit_order.credits.each { |credit| ap credit.change_status Cr_status::USED, credit_order.o_id}
        end
      rescue => e
        ap e
        ap e.inspect
        flash[:error] = e.to_a.flatten.join(": ")
      end
    end
    redirect to("/make_sale/checkout")
  end

  post "/make_sale/cancel" do
    order = Order.new.create_or_load(Order::SALE)
    if order.payments_total == 0
      order.non_destructive_cancel
      flash[:notice] = "Orden cancelada"
      redirect to('/')
    else
      flash[:error] = "No podes cancelar una orden que tiene pagos hechos"
      redirect to('/make_sale')
    end
  end

  post "/make_sale/pro" do
    message = Order.new.create_or_load(Order::SALE).recalculate_as(params[:type].to_sym)
    flash[:notice] = message
    redirect to('/make_sale')
  end

  route :get, :post, "/make_sale/checkout" do
    @order = Order.new.create_or_load(Order::SALE)
    @cart = @order.items_as_cart.all
    @cart_total = @order.cart_total
    @payments = @order.payments
    @payments_total = @order.payments_total
    if @cart.empty?
      flash[:error] = t.sales.make_sale.cant_checkout_empty_order
      redirect to("/make_sale")
    end
    slim :sales_checkout, layout: :layout_sales
  end

  post "/make_sale/finish" do
    begin
      DB.transaction do
        @order = Order.new.create_or_load(Order::SALE)
        @cart_total = @order.cart_total
        @payments_total = @order.payments_total
        items = @order.items
        if @cart_total - @payments_total > 0
          current_location = User.new.current_location[:name]

          # Line_payment.new.set_all(o_id: @order.o_id, payment_type: Line_payment::CASH, payment_code: "", payment_ammount: @cart_total - @payments_total).save
          # en orders.rb actualizar referencias
          BookRecord.new(b_loc: current_location, o_id: @order.o_id, created_at: Time.now, type: "Venta mostrador", description: "#{items.count}", amount: @cart_total - @payments_total).save
        end
        items.each { |item| item.change_status Item::SOLD, @order.o_id }
        @order.change_status Order::FINISHED
        @cart = @order.items_as_cart.all
      end
    rescue Sequel::ValidationFailed => e
      flash[:error] = e.message
      redirect to("/make_sale")
    end

    headers "Refresh" => "5; /sales"

    html = slim :sales_bill, layout: :layout_print

    kit = PDFKit.new(html, page_size: 'a4', print_media_type: true)
    kit.stylesheets << "public/backend.css"
    kit.stylesheets << "public/print.css"
    pdf_file = kit.to_pdf
    filename = ('a'..'z').to_a.shuffle[0,8].join
    tmp = Tempfile.new([filename, ""])
    tmp.binmode
    tmp << pdf_file
    tmp.close
    send_file tmp.path, filename: "#{filename}", type: 'application/pdf', disposition: 'inline'
    tmp.unlink
  end

  post '/reprint_sale/:o_id' do
    @order = Order[params[:o_id]]
    @cart_total = @order.cart_total
    @payments_total = @order.payments_total
    @cart = @order.items_as_cart.all
    html = slim :sales_bill, layout: :layout_print

    kit = PDFKit.new(html, page_size: 'a4', print_media_type: true)
    kit.stylesheets << "public/backend.css"
    kit.stylesheets << "public/print.css"
    pdf_file = kit.to_pdf
    filename = ('a'..'z').to_a.shuffle[0,8].join
    tmp = Tempfile.new([filename, ""])
    tmp.binmode
    tmp << pdf_file
    tmp.close
    send_file tmp.path, filename: "#{filename}", type: 'application/pdf', disposition: 'inline'
    tmp.unlink
  end
end
