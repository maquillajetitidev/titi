module ApplicationHelper
  def save_and_redirect object, redirect
    if object.errors.count == 0 && object.valid?
      object.save
      flash[:notice] = eval("R18n.t.#{object.class.to_s.downcase}.updated")
    else
      flash[:error] = object.errors
    end
    redirect to redirect
  end

  def redirect_if_has_errors object, redirect
    if object.errors.size > 0
      flash[:error] = object.errors.to_a.flatten.join(": ")
      redirect to redirect
    end
  end

  def redirect_if_empty_or_nil object, redirect
    if object.nil? or object.empty?
      flash[:error] = R18n.t.errors.invalid_params
      redirect to redirect
    end
  end

  def redirect_if_nil_order order, o_id, route
    if order.nil?
      flash[:error] = t.order.missing o_id.to_i
      redirect to(route)
    end
  end

  def redirect_if_empty_order order, o_id, route
    if order.empty?
      flash[:error] = t.order.missing o_id
      redirect to(route)
    end
  end

  def redirect_if_nil_material material, p_id, route
    if material.nil?
      flash[:error] = t.material.missing p_id
      redirect to(route)
    end
    unless material.valid?
      flash[:error] = material.errors
      redirect to(route)
    end
  end

  def redirect_if_nil_bulk bulk, b_id, route
    if bulk.nil?
      flash[:error] = t.bulk.missing b_id
      redirect to(route)
    end
  end

  def redirect_if_nil_product product, p_id, route
    if product.nil? or product.empty?
      flash[:error] = t.product.missing p_id.to_s
      redirect to(route)
    end
    unless product.errors.count == 0  and product.valid?
      flash[:error] = product.errors
      redirect to(route)
    end
  end

  def redirect_if_nil_item item, i_id, route
    i_id = i_id.to_s.strip
    if item.nil?
      flash[:error] = t.item.missing i_id
      redirect to(route)
    end
    unless item.errors.count == 0  and item.valid?
      flash[:error] = item.errors
      redirect to(route)
    end
  end

  def o_type_from_route
    case env["sinatra.route"]
    when /wh_to_wh/
      Order::WH_TO_WH
    when /wh_to_pos/
      Order::WH_TO_POS
    when /pos_to_wh/
      Order::POS_TO_WH
    end
  end

end
