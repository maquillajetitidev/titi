class Sales < AppController


  route :get, :post, '/returns' do
    preexistent_return_order = Order.filter(type: Order::RETURN, o_status: Order::OPEN, u_id: current_user_id, o_loc: current_location[:name]).first
    if preexistent_return_order.nil?
      @sale_order = get_sale_order_by_code_or_redirect params[:o_code], "/returns"
      @sale_cart = @sale_order.items_as_cart unless @sale_order.empty?
      slim :returns, layout: :layout_sales, locals: {sec_nav: false}
    else
      sale_order = Order[SalesToReturn.filter(return: preexistent_return_order.o_id).first[:sale]]
      flash[:warning] = "Ya hay una orden de devolucion abierta con anterioridad"
      redirect to( "/returns/#{sale_order.o_code}")
    end
  end


  route :get, :post, '/returns/:o_code' do
    @sale_order = get_sale_order_by_code_or_redirect params[:o_code], "/returns"
    @sale_cart = @sale_order.items_as_cart.all unless @sale_order.empty?
    @return_order = Order.new.create_or_load_return_for_sale @sale_order.o_id
    unless params[:i_id].nil?
      @item = Item.new.get_for_return params[:i_id], @return_order.o_id
      @return_order.add_item @item unless @item.empty?
      @item.change_status(Item::RETURNING, @return_order.o_id).save
    end
    @return_cart = @return_order.detailed_items_as_cart.all unless @return_order.empty?
    flash.now[:error] = @return_order.errors if @return_order.errors.count > 0
    flash.now[:error] = @item.errors if !params[:i_id].nil? && @item.errors.count > 0
    slim :returns, layout: :layout_sales, locals: {sec_nav: false}
  end


  route :post, '/returns/:o_id/cancel' do
    order = Order.new.get_orders_at_location_with_type_status_and_id current_location[:name], Order::RETURN, Order::OPEN, params[:o_id].to_i
    redirect_if_nil_order order, params[:o_id].to_i, "/returns"
    if order.cancel_return
      flash[:notice] = "Orden borrada. Todos los items volvieron al estado Vendido"
    else
      flash[:error] = "Fallo el borrado de la orden"
    end
    redirect to ("/returns")
  end


  route :post, '/returns/:o_id/finish' do
    order = Order.new.get_orders_at_location_with_type_status_and_id current_location[:name], Order::RETURN, Order::OPEN, params[:o_id].to_i
    redirect_if_nil_order order, params[:o_id].to_i, "/returns"
    begin
      credit_order = Order.new.create Order::CREDIT_NOTE
      Credit_note.new.set_all(o_id: credit_order.o_id, cr_desc: "NC Emitida segun devolucion #{order.o_code_with_dash}", cr_ammount: order.cart_total * -1, cr_status: Cr_status::READY).save
      if order.finish_return
        flash[:notice] = t.return.finished
        redirect to ("/credit_notes/get_pdf/#{credit_order.o_code}")
      else
        raise t.return.failed
      end
    rescue => e
      flash[:error] = e.message
      redirect to ("/returns")
    end
  end


  route :get, '/credit_notes/get_pdf/:o_code' do
    o_code = Order.new.remove_dash_from_code params[:o_code].to_s.strip
    order = Order.new.get_orders_at_location_with_type_status_and_code current_location[:name], Order::CREDIT_NOTE, Order::OPEN, o_code
    slim :print_credit_note, layout: :layout_sales, locals: {credit_total: Utils::money_format(order.credit_total, 2), o_code: order.o_code_with_dash}
  end


  route :post, '/credit_notes/get_pdf/:o_code' do
    o_code = Order.new.remove_dash_from_code params[:o_code].to_s.strip
    order = Order.new.get_orders_at_location_with_type_status_and_code current_location[:name], Order::CREDIT_NOTE, Order::OPEN, o_code
    credits = order.credits


    headers "Refresh" => "Refresh: 10; /sales"

    html = slim :credit_note, layout: :layout_print, locals: {order: order, credits: credits}
    kit = PDFKit.new(html, :page_size => 'a4')
    kit.stylesheets << "public/backend.css"
    kit.stylesheets << "public/print.css"
    pdf_file = kit.to_pdf

    tmp = Tempfile.new(["nc-#{order.o_code}", "pdf"])
    tmp.binmode
    tmp << pdf_file
    tmp.close
    send_file tmp.path, filename: "nc-#{order.o_code}.pdf", type: 'application/pdf', disposition: 'attachment'
    tmp.unlink
  end


  def get_sale_order_by_code_or_redirect o_code, redir
    order = Order.new.get_orders_at_location_with_type_status_and_code current_location[:name], Order::SALE, Order::FINISHED, o_code
    if order.empty? && !params[:o_code].nil?
      flash[:error] = order.errors.to_a.flatten.join(": ")
      redirect to(redir)
    end
    order
  end


end

