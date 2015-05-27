# coding: UTF-8

class Item < Sequel::Model
  many_to_one :product, key: :p_id
  many_to_many :orders, class: :Order, join_table: :line_items, left_key: :i_id, right_key: :o_id
  ATTRIBUTES = [:i_id, :p_id, :p_name, :i_price, :i_price_pro, :i_status, :i_loc, :created_at, :updated_at]
  # same as ATTRIBUTES but with the neccesary table references for get_ functions
  COLUMNS = [:items__i_id, :p_id, :p_name, :i_price, :i_price_pro, :i_status, :i_loc, :items__created_at, :items__updated_at]


  def category
    raw = Category
      .select_group(*Category::COLUMNS)
      .join(:products, [:c_id])
      .join(:items, [:p_id])
      .where(products__p_id: self.p_id)
      .where(i_id: self.i_id)
      .first

    cat = Category.new
    cat.c_id = raw[:c_id]
    cat.c_name = raw[:c_name]
    cat.description = raw[:description]
    cat.c_published = raw[:c_published]
    cat.img = raw[:img]
    cat
  end

  def get_by_id i_id
    return Item.new if i_id.to_i == 0
    Item[i_id.to_s]
  end

  def get_via_p_id p_id
    Item
      .select_group(*Item::COLUMNS)
      .where(p_id: p_id)
  end

  def in_orders
    Order
      .select(*Order::COLUMNS)
      .join(:line_items, line_items__o_id: :orders__o_id)
      .join(:items, line_items__i_id: :items__i_id)
      .where(line_items__i_id: self.i_id)
      .order(:o_id)
  end

  def last_order
    in_orders
      .last
  end


  def save (opts=OPTS)
    opts = opts.merge({columns: Item::ATTRIBUTES})
    begin
      ret = super opts
    rescue => message
      errors.add "General", message
    end
    self
  end


  def dissociate o_id=nil
    DB.transaction do
      current_user_id =  User.new.current_user_id
      current_location = User.new.current_location[:name]
      message = R18n::t.product.item_removed
      ActionsLog.new.set(msg: message, u_id: current_user_id, l_id: current_location, lvl: ActionsLog::NOTICE, i_id: @values[:i_id], p_id: @values[:p_id], o_id: o_id).save

      defaults = Item
                  .select{default(:p_id).as(p_id)}
                  .select_append{default(:p_name).as(p_name)}
                  .select_append{default(:i_price).as(i_price)}
                  .select_append{default(:i_price_pro).as(i_price_pro)}
                  .select_append{default(:i_status).as(i_status)}
                  .first
      @values[:p_id]        = defaults[:p_id]
      @values[:p_name]      = defaults[:p_name]
      @values[:i_price]     = defaults[:i_price]
      @values[:i_price_pro] = defaults[:i_price_pro]
      @values[:i_status]    = Item::PRINTED
      save validate: false
      self
    end
  end

  def transmute! reason, p_id
    raise SecurityError if @values[:i_status] != Item::READY
    reason = check_reason reason
    product = check_product_for_transmutation p_id
    original = self.dup

    current_user_id =  User.new.current_user_id
    current_location = User.new.current_location[:name]

    order = Order.new.create_transmutation current_location
    order.add_item self
    @values[:p_id] = product.p_id
    @values[:p_name] = product.p_name
    @values[:i_price] = product.price
    @values[:i_price_pro] = product.price_pro
    save

    message = "Item Transmutado: #{original.p_name} -> #{@values[:p_name]}. Razon: #{reason}"
    log = ActionsLog.new.set(msg: message, u_id: current_user_id, l_id: @values[:i_loc], lvl: ActionsLog::WARN, o_id: order.o_id, i_id: @values[:i_id], p_id: @values[:p_id])
    log.save

    product = Product[original.p_id]
    product.update_stocks.save unless product.nil?
    product = Product[self.p_id]
    product.update_stocks.save unless product.nil?

    order.change_status Order::FINISHED


    self
  end

  def get_items
    Item
      .join(:products, [:p_id])
      .join(:categories, [:c_id])
      .order(:items__p_name)
  end

  def get_items_at_location location
    get_items
      .filter(i_loc: location)
  end

  def get_items_at_location_with_status location, status
    get_items_at_location(location)
      .filter(i_status: status.to_s)
  end


  def order_missmatch sale_id
    return false if self.sale_id == sale_id
    errors.add("Error de ingreso", "Este item pertenece a la orden #{self.sale_id}, mientras que la orden de venta actual es la #{sale_id}.")
    return true
  end

  def missing i_id
    if Item[i_id].nil?
      errors.add("Etiqueta inválida", "No tengo ningun item con el id '#{i_id}'")
      return true
    end
    return false
  end

  def is_from_production
    if @values[:i_status] == Item::NEW or @values[:i_status] == Item::PRINTED or @values[:i_status] == Item::ASSIGNED or @values[:i_status] == Item::MUST_VERIFY or @values[:i_status] == Item::VERIFIED
      errors.add("Item fuera de lugar", "Este item esta en estado \"#{ConstantsTranslator.new(@values[:i_status]).t}\". Ni siquiera deberia estar en el local.")
      return true
    end
    return false
  end

  def is_from_another_location
    if @values[:i_loc] != User.new.current_location[:name]
      errors.add("Item fuera de lugar", "Este item pertenece a \"#{ConstantsTranslator.new(@values[:i_loc]).t}\". Ni siquiera deberia estar aqui.")
      return true
    end
    return false
  end

  def is_a_different_product products_array
    return false if (products_array - [self]).count < products_array.count
    errors.add("Item no corresponde", "Este item \"#{self.p_name}\" no es del producto que necesito.")
    return true
  end

  def current_sale_order
    Order
      .select(:orders__o_id, :type, :o_status, :o_loc, :u_id, :orders__created_at)
      .join(:line_items, line_items__o_id: :orders__o_id, orders__type: Order::SALE)
      .join(:items, line_items__i_id: :items__o_id, line_items__i_id: @values[:i_id])
      .first
  end

  def is_on_cart o_id
    return false unless @values[:i_status] == Item::ON_CART
    order = current_sale_order
    if o_id == current_sale_order.o_id
      errors.add("Error de carga", "Este item ya fue agregado a la orden actual con anterioridad.")
      return true
    else
      errors.add("Item en otra venta en curso", "Este item pertenece a la orden #{order.o_id}. Que haces agregandolo a esta orden??")
      return true
    end
  end


  def is_in_some_order o_id
    return false if self.i_status == Item::READY
    orders = in_orders
    orders.each do |order|
      if order.o_id == o_id
        errors.add("Error de carga", "Este item ya fue agregado a la orden actual con anterioridad.")
        return true
      end
    end
    errors.add("Error de carga", "Este item pertenece a la orden. #{orders.last.o_id}") if orders.last.o_id != o_id
    return true
  end

  def has_been_sold
    if @values[:i_status] == Item::SOLD
      errors.add("Item vendido anteriormente", "Este item ya fue vendido. Que hace aqui otra vez?")
      return true
    end
    return false
  end

  def is_non_saleable
    unless self.p_id.nil?
      product = Product[self.p_id]
      if !product.nil? && product.non_saleable
        errors.add("Este item no es para la venta", "Este item es parte de un kit y no puede venderse por separado")
        return true
      end
    end
    return false
  end

  def has_been_void
    if @values[:i_status] == Item::VOID
      errors.add("Item anulado", "Este item fue Invalidado. No podes operar sobre el.")
      return true
    end
    return false
  end

  def is_sample
    if @values[:i_status] == Item::SAMPLE
      errors.add("Item convertido a muestra", "Este item fue convertido a muestra. No podes hacer esta operacion sobre el.")
      return true
    end
    return false
  end

  def is_returning
    if self.i_status == Item::RETURNING
      errors.add("Item en devolución", "Este item ya está en la devolución. No podes agregarlo nuevamente.")
      return true
    end
    return false
  end

  def has_not_been_sold
    if self.i_status != Item::SOLD
      errors.add(R18n.t.return.errors.invalid_status.to_s, R18n.t.return.errors.this_item_is_not_in_sold_status.to_s)
      return true
    end
    return false
  end

  def is_not_ready
    if @values[:i_status] != Item::READY
      errors.add("Item no listo", "Este item esta en un estado #{ConstantsTranslator.new(@values[:i_status]).t}. No podes operar sobre el.")
      return true
    end
    return false
  end


  def get_for_verification i_id, o_id
    i_id = i_id.to_s.strip
    item = Item.filter(i_status: Item::MUST_VERIFY, i_id: i_id).first
    if item.nil?
      item = Item[i_id]
      if item.nil?
        message = "No tengo ningun item con el id \"#{i_id}\""
        errors.add("Error general", message)
        return self
      end
      item_o_id = Item.select(:o_id).filter(i_id: i_id).join(:line_items, [:i_id]).first[:o_id]
      if item_o_id  == o_id
        message = "Este item ya esta en la orden actual"
        errors.add("Error leve", message)
      else
        if item.i_status == Item::ASSIGNED
          message = "Este item (#{item.i_id}) ya esta asignado a #{item.p_name}"
          errors.add("Error general", message)
        end
        if item.i_status == Item::VOID
          message = "Esta etiqueta fue anulada (#{item.i_id}). Tenias que haberla destruido"
          errors.add("Error general", message)
        end
        if item.i_status == Item::VERIFIED
          message = "Este item ya fue verificado con anterioridad."
          errors.add("Error de ingreso", message)
        elsif item.i_status != Item::MUST_VERIFY
          message = "Esta etiqueta esta en estado \"#{ConstantsTranslator.new(item.i_status).t}\". No podes usarla en esta orden"
          errors.add("Error general", message)
        end
      end
      if errors.count == 0
        message = "No podes utilizar el item #{label.i_id} en la orden actual por que esta en la orden #{item_o_id}"
        errors.add("Error general", message)
      end
      return self
    else
      return item
    end
  end

  def get_for_assembly i_id, o_id, missing_parts
    i_id = i_id.to_s.strip
    missing_p_ids = []
    missing_parts.each {|missing| missing_p_ids << missing.p_id }
    item = Item.filter(i_status: Item::READY, i_loc: User.new.current_location[:name], i_id: i_id).where(p_id: missing_p_ids).first
    return item unless item.nil?
    return self if missing(i_id)
    update_from Item[i_id]
    return self if has_been_void
    return self if is_from_another_location
    return self if is_in_some_order o_id
    return self if is_a_different_product missing_parts
    errors.add("Error inesperado", "Reportar a soporte.")
    return self
  end

  def get_for_sale i_id, o_id
    i_id = i_id.to_s.strip
    item = Item.filter(i_status: Item::READY, i_loc: User.new.current_location[:name], i_id: i_id).first
    return self if is_non_saleable
    return item unless item.nil?
    return self if missing(i_id)
    update_from Item[i_id]
    return self if has_been_void
    return self if is_from_production
    return self if is_from_another_location
    return self if is_on_cart o_id
    return self if has_been_sold
    return self if is_non_saleable
    return self if is_sample
    errors.add("Error inesperado", "Reportar a soporte.")
    return self
  end

  def get_for_transport i_id, o_id
    i_id = i_id.to_s.strip
    item = Item.filter(i_status: Item::READY, i_loc: User.new.current_location[:name], i_id: i_id).first
    return self if is_non_saleable
    return item unless item.nil?
    return self if missing(i_id)
    update_from Item[i_id]
    return self if has_been_void
    return self if is_sample
    return self if is_from_another_location
    return self if has_been_sold # TODO: anulacion de venta
    return self if is_in_some_order o_id
    errors.add("Error inesperado", "Reportar a soporte.")
    return self
  end

  def get_for_removal i_id, o_id
    i_id = i_id.to_s.strip
    item = Item.filter(i_loc: User.new.current_location[:name], i_id: i_id).join(:line_items, [:i_id]).filter(o_id: o_id).first
    return item unless item.nil?
    return self if missing(i_id)
    update_from Item[i_id]
    return self if has_been_void
    return self if is_from_another_location
    return self if has_been_sold # TODO: anulacion de venta
    return self if is_in_some_order o_id
    errors.add("Error inesperado", "Reportar a soporte.")
    return self
  end

  def get_for_transmutation i_id
    i_id = i_id.to_s.strip
    item = Item.filter(i_status: Item::READY, i_id: i_id).first
    return item unless item.nil?
    return self if missing(i_id)
    update_from Item[i_id]
    return self if has_been_void
    return self if has_been_sold
    return self if is_not_ready
    errors.add("Error inesperado", "Reportar a soporte.")
    return self
  end

  def get_for_return i_id, return_id
    i_id = i_id.to_s.strip
    return self if missing(i_id)
    sale = SalesToReturn.filter(:return=>return_id).first
    if sale.nil?
      errors.add("orden inválida", "No tengo ninguna orden de devolucion con el id '#{return_id}'")
      return self
    end
    sale_id = sale[:sale]
    item = Item
            .filter(i_status: Item::SOLD, i_loc: User.new.current_location[:name], type: Order::SALE, i_id: i_id, o_id: sale_id)
            .join(:line_items, [:i_id])
            .join(:orders, [:o_id])
            .order(:orders__o_id)
            .last

    return self if is_non_saleable
    return item unless item.nil?
    return self if missing(i_id)
    item = Item
            .filter(i_id: i_id, type: Order::SALE)
            .join(:line_items, [:i_id])
            .join(:orders, [:o_id])
            .order(:orders__o_id)
            .last
    if item.nil?
      item = Item
              .filter(i_id: i_id)
              .join(:line_items, [:i_id])
              .join(:orders, [:o_id])
              .order(:orders__o_id)
              .last
    end
    update_from item
    return self if is_returning
    return self if has_not_been_sold
    return self if order_missmatch sale_id
    return self if has_been_void
    return self if is_from_production
    return self if is_from_another_location
    return self if is_on_cart return_id
    errors.add("Error inesperado", "Reportar a soporte.")
    return self
  end


end
