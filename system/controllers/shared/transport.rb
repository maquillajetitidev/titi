module Transport

  def enqueue_products order
    p_ids = Set.new
    order.items.each { |item| p_ids.add item.p_id }
    Product.where(p_id: p_ids.to_a).all.each { |product| enqueue product }
  end

  def redir_if_erroneous_item order, item # TODO: kill
    if item.errors.count > 0
      message = item.errors.to_a.flatten.join(": ")
      ActionsLog.new.set(msg: message, u_id: current_user_id, l_id: current_location[:name], lvl: ActionsLog::ERROR, o_id: order.o_id, p_id: item.p_id).save
      flash[:error_add_item] = item.errors
      redirect to("/transport/arrivals/#{order.o_id}")
    end
  end

  def redir_if_erroneous_bulk order, bulk # TODO: kill
    if bulk.errors.count > 0
      message = bulk.errors.to_a.flatten.join(": ")
      ActionsLog.new.set(msg: message, u_id: current_user_id, l_id: current_location[:name], lvl: ActionsLog::ERROR, o_id: order.o_id, m_id: bulk.m_id).save
      flash[:error_add_bulk] = bulk.errors
      redirect to("/transport/arrivals/#{order.o_id}")
    end
  end

  def redir_if_erroneous_order order, type # TODO: kill
    if order.nil?
      flash[:error] = t.order.missing
      redirect to("/transport/arrivals/select")
    end
  end

  def finish_verification order

    @pending_items = Item.join(:line_items, [:i_id]).filter(o_id: order.o_id).filter(i_status: Item::MUST_VERIFY).all
    @pending_bulks = Bulk.join(:line_bulks, [:b_id]).filter(o_id: order.o_id).filter(b_status: Bulk::MUST_VERIFY).all
    if @pending_items.count > 0 or @pending_bulks.count > 0
      flash[:error] = t.production.verification.still_pending_items
      redirect to("/transport/arrivals/#{order.o_id}")
    else
      begin
        processed_items = 0
        DB.transaction do
          if order.type == Order::WH_TO_POS or order.type == Order::WH_TO_WH or order.type == Order::POS_TO_WH
            order.items.each do |item|
              if item.i_status == Item::VERIFIED
                item.change_status(Item::READY, order.o_id).save
                processed_items += 1
              end
            end
            order.bulks.each do |bulk|
              if bulk.b_status == Bulk::VERIFIED
                bulk.change_status(Bulk::NEW, order.o_id).save
                processed_items += 1
              end
            end
            order.change_status Order::VERIFIED
          end
        end
        flash[:notice] = t.transport.arrivals.ok(processed_items, ConstantsTranslator.new(order.o_dst).t)
      rescue => e
        flash[:error] = e.message
      end

      enqueue_products order

      redirect to("/transport/arrivals/select")
    end
  end

  def get_orders_at_location_with_type_status_and_id_or_redirect location, type, status, o_id, redirect
    order = Order.new.get_orders_at_location_with_type_status_and_id location, type, status, o_id
    redirect_if_nil_order order, o_id.to_i, redirect
    order
  end

  def get_item_for_transport i_id, order
    return Item.new if i_id.nil?
    item = Item.new.get_for_transport i_id.to_s.strip, order.o_id
    flash.now[:error] = item.errors.to_a.flatten.join(": ") if item.errors.size > 0
    return item
  end

  def get_item_for_removal i_id, order
    return Item.new if i_id.nil?
    item = Item.new.get_for_removal i_id.to_s.strip, order.o_id
    flash.now[:error] = item.errors.to_a.flatten.join(": ") if item.errors.size > 0
    return item
  end

  def get_bulk_for_removal b_id, order
    return Bulk.new if b_id.nil?
    bulk = Bulk.new.get_for_removal b_id.to_s.strip, order.o_id
    flash.now[:error] = bulk.errors.to_a.flatten.join(": ") if bulk.errors.size > 0
    return bulk
  end


  def get_product_from_item item
    product = item.nil? or item.empty? or item.p_id.nil? ? Product.new : Product[item.p_id]
  end

  def add_item_to_transport_order order, item, product
    begin
      if item.errors.size == 0
        order.add_item item
        if order.errors.size == 0
          item.change_status Item::MUST_VERIFY, order.o_id
          flash.now[:notice] = t.order.item_added product.p_name, order.o_id
        end
      end
    rescue => detail
      flash.now[:error] = detail.message
    end
  end

  def remove_item_from_order order, item
    order.remove_item item
    if order.errors.size == 0
      item.change_status Item::READY, order.o_id
      if item.errors.size == 0
        flash[:warning] = t.item.deleted_from_order
      else
        flash[:error] = item.errors.to_a.flatten.join(": ")
      end
    else
      flash[:error] = order.errors.to_a.flatten.join(": ")
    end
  end

  def remove_bulk_from_order order, bulk
    order.remove_bulk bulk
    if order.errors.size == 0
      bulk.change_status Bulk::NEW, order.o_id
      if bulk.errors.size == 0
        flash[:warning] = "Granel borrado de la orden. Sigue siendo un granel valido para utilizarlo en otra orden"
      else
        flash[:error] = bulk.errors.to_a.flatten.join(": ")
      end
    else
      flash[:error] = order.errors.to_a.flatten.join(": ")
    end
  end

  def verify order, type, id = nil
    redir_if_erroneous_order order, type
    if id
      id = id.to_s.strip
      if id.size == 12
        @item = Item.new.get_for_verification id, order.o_id
        redir_if_erroneous_item order, @item
        begin
          @item.change_status Item::VERIFIED, order.o_id

          flash[:notice] = t.verification.ok @item.i_id, @item.p_name
          redirect to("/transport/arrivals/#{order.o_id}")
        rescue => detail
          flash.now[:error] = detail.message
        end
      elsif id.size == 13
        @bulk = Bulk.new.get_for_verification id, order.o_id
        redir_if_erroneous_bulk order, @bulk
        begin
          @bulk.change_status Bulk::VERIFIED, order.o_id
          @bulk = Bulk.new.get_by_id @bulk.b_id
          flash[:notice] = t.verification.ok @bulk.b_id, @bulk[:m_name]
          redirect to("/transport/arrivals/#{order.o_id}")
        rescue => detail
          flash.now[:error] = detail.message
        end
      end
    end

    @order = order
    @item ||= Item.new
    @product = @item.empty? ? Product.new : Product[@item.p_id]
    @pending_items = Item.join(:line_items, [:i_id]).filter(o_id: @order.o_id).filter(i_status: Item::MUST_VERIFY).order(:p_name).all
    @verified_items = Item.join(:line_items, [:i_id]).filter(o_id: @order.o_id).filter(i_status: Item::VERIFIED).order(:p_name).all
    @void_items = Item.join(:line_items, [:i_id]).filter(o_id: @order.o_id).filter(i_status: Item::ERROR).order(:p_name).all

    @bulk ||= Bulk.new
    @pending_bulks = Bulk.left_join(:materials, [:m_id]).join(:line_bulks, [:b_id]).filter(o_id: @order.o_id).filter(b_status: Bulk::MUST_VERIFY).order(:m_name).all
    @verified_bulks = Bulk.left_join(:materials, [:m_id]).join(:line_bulks, [:b_id]).filter(o_id: @order.o_id).filter(b_status: Bulk::VERIFIED).order(:m_name).all
    @void_bulks = Bulk.left_join(:materials, [:m_id]).join(:line_bulks, [:b_id]).filter(o_id: @order.o_id).filter(b_status: Bulk::ERROR).order(:m_name).all
    case order.type
      when Order::WH_TO_POS
        @module ="sales"
        @route = "transport/arrivals/wh_to_pos"
        slim :verify_transport_order, layout: :layout_sales, locals: {sec_nav: :nav_sales_transport}
      when Order::POS_TO_WH
        @module ="admin"
        @route = "transport/arrivals/pos_to_wh"
        slim :verify_transport_order, layout: :layout_backend, locals: {sec_nav: :nav_production}
      when Order::WH_TO_WH
        @module ="admin"
        @route = "transport/arrivals/wh_to_wh"
        slim :verify_transport_order, layout: :layout_backend, locals: {sec_nav: :nav_production}
    end
  end

end




class Sales < AppController
  include Transport

  route :get, ["/transport/departures/pos_to_wh/select"] do
    @orders = Order.new.get_orders_at_location_with_type_and_status current_location[:name], Order::POS_TO_WH, Order::OPEN
    slim :pos_to_wh_select, layout: :layout_sales, locals: {sec_nav: :nav_sales_transport}
  end

  post '/transport/departures/pos_to_wh/new' do
    order = Order.new.create_or_load Order::POS_TO_WH
    redirect to("/transport/departures/#{order.type.downcase}/#{order.o_id}/add")
  end

  route :get, :post, ['/transport/departures/pos_to_wh/:o_id/add'] do
    @order = get_orders_at_location_with_type_status_and_id_or_redirect current_location[:name], o_type_from_route, Order::OPEN, params[:o_id].to_i, "/transport/departures/pos_to_wh/select"
    @item = get_item_for_transport params[:i_id], @order
    @product = get_product_from_item @item
    add_item_to_transport_order @order, @item, @product

    @items = @order.items
    @module ="/sales"
    @route = "/transport/departures/#{@order.type.downcase}"
    slim :select_item_to_add_to_transport_order, layout: :layout_sales, locals: {sec_nav: :nav_sales_transport}
  end

  route :get, :post, ['/transport/departures/pos_to_wh/:o_id/item/remove'] do
    @order = get_orders_at_location_with_type_status_and_id_or_redirect current_location[:name], o_type_from_route, Order::OPEN, params[:o_id].to_i, "/transport/departures/pos_to_wh/select"
    if params[:id].nil?
      slim :remove_item, layout: :layout_sales, locals: {sec_nav: :nav_sales_transport, action_url: "/transport/departures/#{@order.type.downcase}/#{@order.o_id}/item/remove", title: t.production.remotion.title(@order.o_id)}
    else
      item = get_item_for_removal params[:id], @order
      redirect_if_has_errors item, "/transport/departures/#{@order.type.downcase}/#{@order.o_id}/add"
      remove_item_from_order @order, item
      redirect to "/transport/departures/#{@order.type.downcase}/#{@order.o_id}/add"
    end
  end


  get '/transport/arrivals/pending' do
    @pending_items = Item.new.get_items_at_location_with_status current_location[:name], Item::MUST_VERIFY
    @void_items = Item.new.get_items_at_location_with_status current_location[:name], Item::ERROR

    @pending_bulks = []
    @void_bulks = []
    slim :pending_arrivals_verifications, layout: :layout_sales, locals: {sec_nav: :nav_sales_transport, include_bulks: false, title: t.transport.arrivals.pending_items_and_errors.title}
  end

  route :get, ["/transport/arrivals", "/transport/arrivals/select"] do
    @orders = Order.new.get_orders_at_destination_with_type_and_status(current_location[:name], Order::WH_TO_POS, Order::EN_ROUTE).all
    slim :orders_list, layout: :layout_sales, locals: {title: t.transport.arrivals.title, sec_nav: :nav_sales_transport, full_row: true, list_mode: "transport", show_edit_button: true, edit_link: "/sales/transport/arrivals/o_id", show_filters: false}
  end

  route :get, :post, '/transport/arrivals/:o_id' do
    order = Order.new.get_orders_at_location_with_type_status_and_id(current_location[:name], Order::WH_TO_POS, Order::EN_ROUTE, params[:o_id])
    verify order, Order::WH_TO_POS, params[:i_id]
  end

  route :get, :post, ['/transport/arrivals/wh_to_pos/:o_id/item/remove'] do
    @order = get_orders_at_location_with_type_status_and_id_or_redirect current_location[:name], o_type_from_route, Order::EN_ROUTE, params[:o_id].to_i, "/transport/arrivals/select"
    if params[:id].nil?
      slim :remove_item, layout: :layout_sales, locals: {sec_nav: :nav_sales_transport, action_url: "/transport/arrivals/wh_to_pos/#{@order.o_id}/item/remove", title: t.production.remotion.title(@order.o_id)}
    else
      @item = get_item_for_removal params[:id], @order
      redirect_if_has_errors @item, "/transport/arrivals/#{@order.o_id}"
      begin
        @item.change_status(Item::ERROR, params[:o_id].to_i)
      rescue => detail
        flash.now[:error] = detail.message
      end
      slim :void_item, layout: :layout_sales, locals: {show_backlink: true, backlink: "/sales/transport/arrivals/#{@order.o_id}"}
    end
  end

  route :post,  ["/transport/departures/pos_to_wh/:o_id/move/?"] do
    o_type = o_type_from_route

    order = get_orders_at_location_with_type_status_and_id_or_redirect current_location[:name], o_type_from_route, Order::OPEN, params[:o_id].to_i, "/transport/departures/#{o_type_from_route}/select"
    begin
      DB.transaction do
        order[:o_dst] = params[:o_dst] if Location.new.valid? params[:o_dst]
        order.save columns: [:o_dst]
        order.change_status(Order::EN_ROUTE)
        order.items.each do |item|
          item.i_loc=params[:o_dst] if Location.new.valid? params[:o_dst]
          item.save
        end
      end
    rescue => e
      flash[:error] = e.message
    end

    enqueue_products order

    redirect to "/transport/departures/#{order.type.downcase}/select"
  end

  post '/transport/arrivals/:o_id/finish' do
    finish_verification Order.new.get_orders_at_location_with_type_status_and_id(current_location[:name], Order::WH_TO_POS, Order::EN_ROUTE, params[:o_id])
  end

end


















class Backend < AppController
  include Transport

  route :get, :post, ['/transport/arrivals/pos_to_wh/:o_id/item/remove', '/transport/arrivals/wh_to_wh/:o_id/item/remove'] do
    @order = get_orders_at_location_with_type_status_and_id_or_redirect current_location[:name], o_type_from_route, Order::EN_ROUTE, params[:o_id].to_i, "/transport/arrivals/select"
    if params[:id].nil?
      slim :remove_item, layout: :layout_backend, locals: {sec_nav: :nav_production, action_url: "/transport/arrivals/#{@order.type.downcase}/#{@order.o_id}/item/remove", title: t.production.remotion.title(@order.o_id)}
    else
      @item = get_item_for_removal params[:id], @order
      redirect_if_has_errors @item, "/transport/arrivals/#{@order.o_id}"
      begin
        @item.change_status(Item::ERROR, params[:o_id].to_i)
      rescue => detail
        flash.now[:error] = detail.message
      end
      ap Item.new.get_by_id @item.i_id
      slim :void_item, layout: :layout_sales, locals: {show_backlink: true, backlink: "/admin/transport/arrivals/#{@order.o_id}"}
    end
  end

  route :get, :post, ['/transport/arrivals/wh_to_wh/:o_id/bulk/remove'] do
    @order = get_orders_at_location_with_type_status_and_id_or_redirect current_location[:name], o_type_from_route, Order::EN_ROUTE, params[:o_id].to_i, "/transport/arrivals/select"
    if params[:id].nil?
      slim :remove_item, layout: :layout_backend, locals: {sec_nav: :nav_production, action_url: "/transport/arrivals/wh_to_wh/#{@order.o_id}/bulk/remove", title: t.production.bulk_remotion.title(@order.o_id)}
    else
      @bulk = get_bulk_for_removal params[:id], @order
      redirect_if_has_errors @bulk, "/transport/arrivals/#{@order.o_id}"

      begin
        @bulk.change_status(Bulk::ERROR, params[:o_id].to_i)
      rescue => detail
        flash.now[:error] = detail.message
      end
      ap Bulk.new.get_by_id @bulk.b_id
      slim :void_bulk, layout: :layout_backend, locals: {show_backlink: true, backlink: "/admin/transport/arrivals/#{@order.o_id}"}
    end
  end




  route :get, :post, ['/transport/departures/wh_to_wh/:o_id/item/remove', '/transport/departures/wh_to_pos/:o_id/item/remove'] do
    @order = get_orders_at_location_with_type_status_and_id_or_redirect current_location[:name], o_type_from_route, Order::OPEN, params[:o_id].to_i, "/transport/departures/#{o_type_from_route}/select"
    if params[:id].nil?
      slim :remove_item, layout: :layout_backend, locals: {sec_nav: :nav_production, action_url: "/transport/departures/#{@order.type.downcase}/#{@order.o_id}/item/remove", title: t.production.remotion.title(@order.o_id)}
    else
      item = get_item_for_removal params[:id], @order
      redirect_if_has_errors item, "/transport/departures/#{@order.type.downcase}/#{@order.o_id}/add"
      remove_item_from_order @order, item
      redirect to "/transport/departures/#{@order.type.downcase}/#{@order.o_id}/add"
    end
  end

  route :get, :post, ['/transport/departures/wh_to_wh/:o_id/bulk/remove'] do
    @order = get_orders_at_location_with_type_status_and_id_or_redirect current_location[:name], o_type_from_route, Order::OPEN, params[:o_id].to_i, "/transport/departures/wh_to_wh/select"
    if params[:id].nil?
      slim :remove_item, layout: :layout_backend, locals: {sec_nav: :nav_production, action_url: "/transport/departures/wh_to_wh/#{@order.o_id}/bulk/remove", title: t.production.bulk_remotion.title(@order.o_id)}
    else
      bulk = get_bulk_for_removal params[:id], @order
      redirect_if_has_errors bulk, "/transport/departures/#{@order.type.downcase}/#{@order.o_id}/add"
      remove_bulk_from_order @order, bulk
      redirect to "/transport/departures/#{@order.type.downcase}/#{@order.o_id}/add"
    end
  end

  get '/transport/arrivals/pending' do
    @pending_items = Item.new.get_items_at_location_with_status current_location[:name], Item::MUST_VERIFY
    @void_items = Item.new.get_items_at_location_with_status current_location[:name], Item::ERROR

    @pending_bulks = Bulk.new.get_bulks_in_orders_for_location_and_status(current_location[:name], Bulk::MUST_VERIFY).all
    @void_bulks = Bulk.new.get_bulks_in_orders_for_location_and_status(current_location[:name], Bulk::ERROR).all
    slim :pending_arrivals_verifications, layout: :layout_backend, locals: {sec_nav: :nav_production, include_bulks: true, title: t.transport.arrivals.pending_items_and_errors.title}
  end

  route :get, ["/transport/arrivals/select"] do
    @orders = Order.new.get_orders_at_destination_with_type_and_status(current_location[:name], [Order::WH_TO_WH, Order::POS_TO_WH], Order::EN_ROUTE).all
    slim :orders_list, layout: :layout_backend, locals: {title: t.transport.arrivals.title, sec_nav: :nav_production, full_row: true, list_mode: "transport", show_edit_button: true, edit_link: "/admin/transport/arrivals/o_id", show_filters: false}
  end

  route :get, :post, '/transport/arrivals/:o_id' do
    order = Order.new.get_orders_at_location_with_type_status_and_id(current_location[:name], [Order::WH_TO_WH, Order::POS_TO_WH], Order::EN_ROUTE, params[:o_id])
    verify order, Order::WH_TO_WH, params[:i_id]
  end

  post '/transport/arrivals/:o_id/finish' do
    finish_verification Order.new.get_orders_at_location_with_type_status_and_id(current_location[:name], [Order::WH_TO_WH, Order::POS_TO_WH], Order::EN_ROUTE, params[:o_id])
  end

  get '/transport/departures/wh_to_wh/select' do
    orders = Order.new.get_orders_at_location_with_type_and_status(current_location[:name], Order::WH_TO_WH, Order::OPEN).all
    slim :wh_to_wh_select, layout: :layout_backend, locals: {sec_nav: :nav_production, title: t.transport.departures.wh_to_wh.title, orders: orders}
  end

  post '/transport/departures/wh_to_wh/new' do
    order = Order.new.create_or_load Order::WH_TO_WH
    redirect to("/transport/departures/wh_to_wh/#{order.o_id}/add")
  end

  get '/transport/departures/wh_to_pos/select' do
    @orders = Order.new.get_wh_to_pos__open(current_location[:name])
    slim :wh_to_pos_select, layout: :layout_backend, locals: {sec_nav: :nav_production}
  end

  post '/transport/departures/wh_to_pos/new' do
    order = Order.new.create_or_load Order::WH_TO_POS
    redirect to("/transport/departures/wh_to_pos/#{order.o_id}/add")
  end


  route :get, :post, ['/transport/departures/wh_to_wh/:o_id/add/?', '/transport/departures/wh_to_pos/:o_id/add/?'] do
    o_type = o_type_from_route
    @order = Order.new.get_orders_at_location_with_type_status_and_id current_location[:name], o_type, Order::OPEN, params[:o_id].to_i
    redirect_if_nil_order @order, params[:o_id].to_i, "#{@route}/select"
    @route = "/transport/departures/#{@order.type.downcase}"

    if params[:i_id].nil?
    elsif params[:i_id]
      id = params[:i_id].to_s.strip
      if id.size == 12
        @item = Item.new.get_for_transport id.to_s.strip, params[:o_id].to_i
        if @item.errors.size > 0
          flash.now[:error] = @item.errors.to_a.flatten.join(": ")
          @product = Product.new
        else
          begin
            @order.add_item @item
            @item.change_status Item::MUST_VERIFY, params[:o_id].to_i
            @product = Product[@item.p_id]
            flash.now[:notice] = t.order.item_added @product.p_name, @order.o_id
          rescue => detail
            flash.now[:error] = detail.message
            @item = Item.new
          end
        end
      elsif id.size == 13 && o_type == Order::WH_TO_WH
        @bulk = Bulk.new.get_for_transport id.to_s.strip, params[:o_id].to_i
        if @bulk.errors.size > 0
          flash.now[:error] = @bulk.errors.to_a.flatten.join(": ")
          @material = Material.new
        else
          begin
            @order.add_bulk @bulk
            @bulk.change_status Bulk::MUST_VERIFY, params[:o_id].to_i
            @material = Material[@bulk.m_id]
            flash.now[:notice] = t.order.bulk_added @bulk[:m_name], @order.o_id
          rescue => detail
            flash.now[:error] = detail.message
            @bulk = Bulk.new
          end
        end
      else
        flash.now[:error] = t.errors.invalid_label
      end
    end
    @item ||= Item.new
    @bulk ||= Bulk.new
    @items = @order.items
    @bulks = @order.bulks
    @module = "/admin"
    slim :select_item_to_add_to_transport_order, layout: :layout_backend, locals: {sec_nav: :nav_production}
  end


  route :post,  ["/transport/departures/wh_to_wh/:o_id/move/?", "/transport/departures/wh_to_pos/:o_id/move/?"] do

    order = get_orders_at_location_with_type_status_and_id_or_redirect current_location[:name], o_type_from_route, Order::OPEN, params[:o_id].to_i, "/transport/departures/#{o_type_from_route}/select"
    begin
      DB.transaction do
        order[:o_dst] = params[:o_dst] if Location.new.valid? params[:o_dst]
        order.save columns: [:o_dst]
        order.change_status(Order::EN_ROUTE)
        order.items.each do |item|
          item.i_loc=params[:o_dst] if Location.new.valid? params[:o_dst]
          item.save
        end
        order.bulks.each do |bulk|
          bulk.b_loc=params[:o_dst] if Location.new.valid? params[:o_dst]
          bulk.save
        end
      end
    rescue => e
      flash[:error] = e.message
    end

    enqueue_products order

    redirect to "/transport/departures/#{order.type.downcase}/select"
  end
end

