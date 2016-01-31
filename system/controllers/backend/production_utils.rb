# coding: UTF-8
class Backend < AppController

  require 'date'

  get '/production/labels' do
    slim :labels, layout: :layout_backend, locals: {sec_nav: :nav_production, title: t.labels.title, labels: Label.new.get_unprinted.all}
  end
  get '/production/labels/list' do
    unprinted = Label.new.get_unprinted.all
    printed = Label.new.get_printed.all
    slim :labels, layout: :layout_backend, locals: {sec_nav: :nav_production, title: t.labels.title, labels: unprinted + printed}
  end
  post '/production/labels/csv/?' do
    require 'tempfile'
    barcodes = Label.new.get_as_csv
    tmp = Tempfile.new(["barcodes", ".csv"])
    tmp << barcodes
    tmp.close
    send_file tmp.path, filename: 'barcodes.csv', type: 'octet-stream', disposition: 'attachment'
    tmp.unlink
  end
  post '/production/labels/new' do
    Label.new.create params[:qty].to_i
    redirect to("/production/labels")
  end


  get '/production/items_ingresados' do
    startOfMonth = DateTime.now.strftime('1/%m/%Y')  
    today = DateTime.now.strftime('%d/%m/%Y')
    tercerizedValue = false
    slim :items_ingresados, layout: :layout_backend, locals: {
      sec_nav: :nav_production,
      title: "Items ingresados para un usuario dentro de un rango de fechas:",
      username: State.current_user.username,
      dateFrom: startOfMonth,
      dateTo: today,
      asignatedItemsTercerized: 0,
      asignatedItemsNonTercerized: 0,
      asignatedItemsTotal: 0
    }
  end

  post '/production/items_ingresados/refresh' do
    begin
      username = params[:username]
      dateFrom = Date.strptime(params[:dateFrom],"%d/%m/%Y")
      dateTo = Date.strptime(params[:dateTo],"%d/%m/%Y")
      asignatedItemsTercerized = ActionsLog.new.get_new_items(
        username, dateFrom, dateTo, true)
      asignatedItemsNonTercerized = ActionsLog.new.get_new_items(
        username, dateFrom, dateTo, false)
      # puts params.inspect
      # puts "username -> #{username}"
      # puts "dateFrom -> #{dateFrom}"
      # puts "dateTo -> #{dateTo + 1}"
      # puts "asignatedItemsTercerized -> #{asignatedItemsTercerized}"
      # puts "asignatedItemsNonTercerized -> #{asignatedItemsNonTercerized}"
      slim :items_ingresados, layout: :layout_backend, locals: {
        sec_nav: :nav_production,
        title: "Items ingresados para un usuario dentro de un rango de fechas:",
        username: username,
        dateFrom: params[:dateFrom],
        dateTo: params[:dateTo],
        asignatedItemsTercerized: asignatedItemsTercerized,
        asignatedItemsNonTercerized: asignatedItemsNonTercerized,
        asignatedItemsTotal: asignatedItemsTercerized + asignatedItemsNonTercerized
      }
    rescue => detail
      puts detail.inspect
      redirect to("/production/items_ingresados")
    end
  end


  route :post, ['/production/:order_type/new'] do
    order_type = params[:order_type].upcase
    unless Order::PRODUCTION_TYPES.include? order_type
      flash[:error] = "Tipo de orden inválido"
      redirect to("/production")
    end
    order = Order.new.create_or_load order_type
    redirect to("/production/#{order_type.downcase}/#{order.o_id}")
  end



  get '/production/:action/select' do
    unless Order::PRODUCTION_ACTIONS.include? params[:action].upcase
      flash[:error] = "Tipo de acción inválida"
      redirect to("/production")
    end

    action = params[:action].to_sym
    case action
      when :assembly
        order_type = Order::ASSEMBLY
        order_status = Order::OPEN
        title = t.production.assembly_select.title
      when :packaging
        order_type = Order::PACKAGING
        order_status = Order::OPEN
        title = t.production.packaging_select.title
      when :verification
        order_type = Order::PACKAGING
        order_status = Order::MUST_VERIFY
        title = t.production.verification_select.title
      when :allocation
        order_type = Order::PACKAGING
        order_status = Order::VERIFIED
        title = t.production.allocation_select.title
    end
    orders = Order.new.get_orders_at_location_with_type_and_status(current_location[:name], order_type, order_status).all
    slim :production_select, layout: :layout_backend, locals: {sec_nav: :nav_production, orders: orders, action: action, title: title}
  end




  route :get, :post, '/production/verification/:o_id' do
    order = Order.new.get_orders_at_location_with_type_status_and_id(current_location[:name], Order::PACKAGING, Order::MUST_VERIFY, params[:o_id].to_i)
    redirect_if_nil_order order, params[:o_id].to_i, "/production/verification/select"

    if params[:i_id]
      current_item = Item.new.get_for_verification params[:i_id], order.o_id
      redirect_if_nil_item( current_item, params[:i_id].to_s.strip, "/production/verification/#{order.o_id}" )
      begin
        current_item.change_status Item::VERIFIED, params[:o_id].to_i
        flash.now[:notice] = t.verification.ok current_item.i_id, current_item.p_name
      rescue => detail
        flash.now[:error] = detail.message
      end
    end
    current_item ||= Item.new
    current_product = current_item.empty? ? Product.new : Product[current_item.p_id]
    pending_items = Item.join(:line_items, [:i_id]).filter(o_id: order.o_id).filter(i_status: Item::MUST_VERIFY).order(:p_name).all
    verified_items = Item.join(:line_items, [:i_id]).filter(o_id: order.o_id).filter(i_status: Item::VERIFIED).order(:p_name).all
    slim :verify_packaging, layout: :layout_backend, locals: {
      order: order, current_product: current_product, current_item: current_item, pending_items: pending_items, verified_items: verified_items,
      sec_nav: :nav_production, title: t.production.verification.title(order.o_id, verified_items.count, pending_items.count+verified_items.count )}
  end




  post '/production/:action/:o_id/cancel' do
    unless Order::PRODUCTION_ACTIONS.include? params[:action].upcase
      flash[:error] = "Tipo de acción inválida"
      redirect to("/production")
    end

    action = params[:action].to_sym
    case action
      when :assembly
        order_type = Order::ASSEMBLY
      when :packaging
        order_type = Order::PACKAGING
      when :allocation
        order_type = Order::PACKAGING
    end
    order = Order.new.get_orders_at_location_with_type_and_id(current_location[:name], order_type, params[:o_id].to_i)
    redirect_if_nil_order order, params[:o_id].to_i, "/production/#{action}/select"
    order_type == Order::ASSEMBLY ? non_destructive_cancel_and_redirect(order) :  destructive_cancel_and_redirect(order)
  end

  def destructive_cancel_and_redirect order
    order.cancel
    flash[:warning] = t.order.cancelled( order.o_id )
    redirect to("/production/#{order.type.downcase}/select")
  end

  def non_destructive_cancel_and_redirect order
    order.non_destructive_cancel
    flash[:warning] = t.order.non_destructive_cancelled( order.o_id )
    redirect to("/production/#{order.type.downcase}/select")
  end




  post '/production/verification/:o_id/:i_id/void' do
    @order = Order[params[:o_id].to_i]
    @item = Item[params[:i_id].to_s.strip]
    @order.remove_item(@item)
    begin
      @item.change_status(Item::VOID, params[:o_id].to_i)
    rescue => detail
      flash.now[:error] = detail.message
    end
    slim :void_item, layout: false, locals: {show_backlink: false}
  end




  route :get, :post, ['/production/packaging/:o_id/item/remove', '/production/verification/:o_id/item/remove'] do
    flash.now[:notice] = "Lee La etiqueta recien agregada" if env["REQUEST_METHOD"] == "POST" && params[:id].nil?

    order = Order.new.get_orders_at_location_with_type_and_id(current_location[:name], Order::PACKAGING, params[:o_id].to_i)
    redirect_if_nil_order order, params[:o_id].to_i, "/production/packaging/select"

    if params[:id].nil?
      @order = order
      slim :remove_item, layout: :layout_backend, locals: {sec_nav: :nav_production, action_url: "/production/#{order.current_action}/#{order.o_id}/item/remove", title: t.production.remotion.title(order.o_id)}
    else
      item = Item[params[:id].to_s.strip]
      if item.nil?
        flash[:error] = "No tengo ningun item con ese ID"
        redirect to("/production/#{order.current_action}/#{order.o_id}")
      end
      if item.p_id.nil?
        flash[:error] = "Ese item no esta asignado a ningun producto"
        redirect to("/production/#{order.current_action}/#{order.o_id}")
      end
      unless order.items.include? item
        flash[:error] = "Ese item no pertenece a esta orden"
        redirect to("/production/#{order.current_action}/#{order.o_id}")
      end
      product = Product[item.p_id]
      order.remove_item item
      product.remove_item item
      if order.errors.count > 0 or product.errors.count > 0
        flash[:error] = [order.errors, product.errors]
      else
        flash[:warning] = "Etiqueta dissociada del producto y la orden. Podes asignarla a otro producto."
      end
      redirect to("/production/#{order.current_action}/#{order.o_id}")
    end
  end

  # similar but not the same
  route :get, :post, '/production/assembly/:o_id/item/remove' do
    flash.now[:notice] = "Lee La etiqueta recien agregada" if env["REQUEST_METHOD"] == "POST" && params[:id].nil?

    order = Order.new.get_orders_at_location_with_type_and_id(current_location[:name], Order::ASSEMBLY, params[:o_id].to_i)
    redirect_if_nil_order order, params[:o_id].to_i, "/production/assembly/select"

    if params[:id].nil?
      @order = order
      slim :remove_item, layout: :layout_backend, locals: {sec_nav: :nav_production, action_url: "/production/#{order.current_action}/#{order.o_id}/item/remove", title: t.production.remotion.title(order.o_id)}
    else
      item = Item[params[:id].to_s.strip]
      if item.nil?
        flash[:error] = "No tengo ningun item con ese ID"
        redirect to("/production/#{order.current_action}/#{order.o_id}")
      end
      if item.p_id.nil?
        flash[:error] = "Ese item no esta asignado a ningun producto"
        redirect to("/production/#{order.current_action}/#{order.o_id}")
      end
      unless order.items.include? item
        flash[:error] = "Ese item no pertenece a esta orden"
        redirect to("/production/#{order.current_action}/#{order.o_id}")
      end
      order.remove_item item
      item.change_status Item::READY, order.o_id
      if order.errors.count > 0
        flash[:error] = order.errors
      else
        flash[:warning] = "Item dissociado de la orden. Podes asignarlo a otra orden."
      end
      redirect to("/production/#{order.current_action}/#{order.o_id}")
    end
  end





  post '/production/:action/:o_id/finish' do

    unless Order::PRODUCTION_ACTIONS.include? params[:action].upcase
      flash[:error] = "Tipo de acción inválida"
      redirect to("/production")
    end

    action = params[:action].to_sym
    case action
      when :packaging
        order_type = Order::PACKAGING
        order_status = Order::OPEN
      when :verification
        order_type = Order::PACKAGING
        order_status = Order::MUST_VERIFY
      when :allocation
        order_type = Order::PACKAGING
        order_status = Order::VERIFIED
    end
    order = Order.new.get_orders_at_location_with_type_status_and_id(current_location[:name], order_type, order_status, params[:o_id].to_i)
    redirect_if_nil_order order, params[:o_id].to_i, "/production/#{action}/select"
    # destroy if empty
    destructive_cancel_and_redirect order if order.items.empty?

    routes = [:packaging, :verification, :allocation]
    if order.type ==  Order::PACKAGING && order.o_status == Order::OPEN
      order.finish_load
      ok_message = t.order.ready_for_verification
      route = 1
    elsif order.type ==  Order::PACKAGING && order.o_status == Order::MUST_VERIFY
      order.finish_verification
      ok_message = t.order.ready_for_allocation
      route = 2
    elsif order.type ==  Order::ALLOCATION && order.o_status == Order::VERIFIED
      order.finish_verification
      ok_message = t.order.ready_for_allocation
      route = 3
    end

    if order.errors.count > 0
      flash[:error_finish] = order.errors
      redirect to("/production/#{routes[route-1]}/#{order.o_id}")
    else
      flash[:notice] = ok_message
      redirect to("/production/#{routes[route]}/select")
    end

  end

end
