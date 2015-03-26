require 'sequel'

class Order < Sequel::Model

  require_relative 'order_sql.rb'

  def empty?
    return @values[:o_id].nil? ? true : false
  end

  def current_action
    case self.o_status
      when Order::OPEN
        return self.type.downcase
      when Order::MUST_VERIFY
        return "verification"
      when Order::VERIFIED
        return "allocation"
    end
  end

  def remove_dash_from_code code
    code.to_s.gsub('-', '')
  end

  def o_code_with_dash
    self.o_code.upcase.insert(3, '-') unless self.o_code.nil?
  end

  def valid_type? type
    TYPES.include? type
  end

  def parts
    parts = []
    self.items.each do |item|
      parts << Product.new.get(item.p_id).parts
    end
    parts.flatten
  end

  def add_item item
    current_user_id = User.new.current_user_id
    current_location = User.new.current_location[:name]
    if item.nil?
      message = R18n::t.errors.inexistent_item
      ActionsLog.new.set(msg: "#{message}", u_id: current_user_id, l_id: current_location, lvl:  ActionsLog::ERROR).save
      errors.add "General", message
      return message
    end
    if item.class != Item
      message = R18n::t.errors.this_is_not_an_item(item.class)
      ActionsLog.new.set(msg: "#{message}", u_id: current_user_id, l_id: current_location, lvl:  ActionsLog::ERROR).save
      errors.add "General", message
      return message
    end
    if item.i_status == Item::NEW && !item.i_id.nil?
      message = R18n::t.errors.label_wasnt_printed
      ActionsLog.new.set(msg: message, u_id: current_user_id, l_id: current_location, lvl:  ActionsLog::ERROR, i_id: item.i_id, p_id: item.p_id).save
      errors.add "General", message
      return message
    end
    if item.i_id.nil?
      message = R18n::t.errors.cant_add_empty_items_to_order.to_s
      ActionsLog.new.set(msg: message, u_id: current_user_id, l_id: current_location, lvl:  ActionsLog::ERROR, i_id: item.i_id, p_id: item.p_id).save
      errors.add "General", message
      return message
    end
    if item.errors.count > 0
      message = "#{item.errors.to_a.flatten.join(": ")}"
      ActionsLog.new.set(msg: message, u_id: current_user_id, l_id: current_location, lvl:  ActionsLog::ERROR, i_id: item.i_id, p_id: item.p_id).save
      errors.add item.errors.flatten.flatten[0], item.errors.flatten.flatten[1]
      return message
    end
    begin
      if super
        added_msg = R18n::t.order.item_added(item.p_name, @values[:o_id])
        ActionsLog.new.set(msg: added_msg, u_id: current_user_id, l_id: current_location, lvl:  ActionsLog::NOTICE, i_id: item.i_id, p_id: item.p_id, o_id: @values[:o_id]).save
        return added_msg
      else
        ActionsLog.new.set(msg: this.errors.to_s, u_id: current_user_id, l_id: current_location, lvl:  ActionsLog::ERROR, i_id: item.i_id, p_id: item.p_id).save
        return this.errors.to_s
      end
    rescue Sequel::UniqueConstraintViolation => detail
      errors.add "Error de ingreso", "Item agregado con anterioridad"
    rescue => detail
      errors.add "General", detail.message
      puts detail.message
    end
  end

  def add_bulk bulk
    current_user_id =  User.new.current_user_id
    current_location = User.new.current_location[:name]
    if bulk.nil?
      message = R18n::t.errors.inexistent_bulk
      ActionsLog.new.set(msg: "#{message}", u_id: current_user_id, l_id: current_location, lvl:  ActionsLog::ERROR).save
      errors.add "General", message
      return message
    end
    if bulk.class != Bulk
      message = R18n::t.errors.this_is_not_a_bulk(bulk.class)
      ActionsLog.new.set(msg: "#{message}", u_id: current_user_id, l_id: current_location, lvl:  ActionsLog::ERROR).save
      errors.add "General", message
      return message
    end
    if bulk.b_status == Bulk::UNDEFINED
      message = R18n::t.errors.bulk_in_undefined_status
      ActionsLog.new.set(msg: message, u_id: current_user_id, l_id: current_location, lvl:  ActionsLog::ERROR, b_id: bulk.b_id, m_id: bulk.m_id).save
      errors.add "General", message
      return message
    end
    if @values[:type] != Order::WH_TO_WH
      message = R18n::t.errors.not_a_inter_warehouse_order
      ActionsLog.new.set(msg: message, u_id: current_user_id, l_id: current_location, lvl:  ActionsLog::ERROR, b_id: bulk.b_id, m_id: bulk.m_id, o_id: @values[:o_id]).save
      errors.add "General", message
      return message
    end

    begin
      if super
        added_msg = R18n::t.order.bulk_added(bulk[:m_name], @values[:o_id])
        ActionsLog.new.set(msg: added_msg, u_id: current_user_id, l_id: current_location, lvl:  ActionsLog::NOTICE, b_id: bulk.b_id, m_id: bulk.m_id, o_id: @values[:o_id]).save
        return added_msg
      else
        ActionsLog.new.set(msg: this.errors.to_s, u_id: current_user_id, l_id: current_location, lvl:  ActionsLog::ERROR, b_id: bulk.b_id, m_id: bulk.m_id).save
        return this.errors.to_s
      end
    rescue Sequel::UniqueConstraintViolation => detail
      errors.add "Error de ingreso", "Granel agregado con anterioridad"
    rescue => detail
      errors.add "General", detail.message
      puts detail.message
    end
  end

  def remove_item item
    super
    current_user_id =  User.new.current_user_id
    current_location = User.new.current_location[:name]
    message = R18n::t.order.item_removed
    ActionsLog.new.set(msg: message, u_id: current_user_id, l_id: current_location, lvl: ActionsLog::NOTICE, i_id: item.i_id, p_id: item.p_id, o_id: @values[:o_id]).save
  end

  def remove_bulk bulk
    super
    current_user_id =  User.new.current_user_id
    current_location = User.new.current_location[:name]
    message = R18n::t.order.bulk_removed
    ActionsLog.new.set(msg: message, u_id: current_user_id, l_id: current_location, lvl: ActionsLog::NOTICE, b_id: bulk.b_id, m_id: bulk.m_id, o_id: @values[:o_id]).save
  end

  def remove_all_items
    super
    current_user_id =  User.new.current_user_id
    current_location = User.new.current_location[:name]
    message = R18n::t.order.all_items_removed
    ActionsLog.new.set(msg: message, u_id: current_user_id, l_id: current_location, lvl: ActionsLog::NOTICE, o_id: @values[:o_id]).save
  end

  def remove_all_bulks
    super
    current_user_id =  User.new.current_user_id
    current_location = User.new.current_location[:name]
    message = R18n::t.order.all_bulks_removed
    ActionsLog.new.set(msg: message, u_id: current_user_id, l_id: current_location, lvl: ActionsLog::NOTICE, o_id: @values[:o_id]).save
  end

  def change_status status
    @values[:o_status] = status
    save columns: [:o_status]
    current_user_id =  User.new.current_user_id
    current_location = User.new.current_location[:name]
    message = R18n.t.actions.changed_order_status(ConstantsTranslator.new(status).t)
    ActionsLog.new.set(msg: message, u_id: current_user_id, l_id: current_location, lvl: ActionsLog::INFO, o_id: @values[:o_id]).save
    self
  end

  def print
    out = "\n"
    out += "#{self.class} #{sprintf("%x", self.object_id)}:\n"
    out += "\to_id:  #{@values[:o_id]}\n"
    out += "\ttype:  #{@values[:type]}\n"
    out += "\to_status:  #{@values[:o_status]}\n"
    out += "\to_loc:  #{@values[:o_loc]}\n"
    out += "\to_dst:  #{@values[:o_dst]}\n"
    out += "\tu_id:   #{@values[:u_id]}\n"
    created = @values[:created_at] ? Utils::local_datetime_format(@values[:created_at]) : "Never"
    out += "\tcreated: #{created}\n"
    puts out
  end


  def finish_load
    change_status Order::MUST_VERIFY
  end

  def finish_assembly

    ap "shoud change status"
    ap self.items

    product = self.get_assembly

    ap product.materials
    # change_status Order::FINISHED
  end

  def finish_verification
    pending_items = Item.join(:line_items, [:i_id]).filter(o_id: self.o_id).filter(i_status: Item::MUST_VERIFY).all
    if pending_items.count > 0
      errors.add "Error en verificacion", R18n::t.production.verification.still_pending_items
    else
      change_status Order::VERIFIED
    end
  end

  def finish_return
    DB.transaction do
      items = self.items
      if items.count > 0
        items.each { |item| item.change_status(Item::READY, self.o_id).save if item.i_status == Item::RETURNING }
        self.change_status Order::FINISHED
        save columns: Order::ATTRIBUTES
        current_user_id =  User.new.current_user_id
        current_location = User.new.current_location[:name]
        message = R18n.t.return.finished
        ActionsLog.new.set(msg: message, u_id: current_user_id, l_id: current_location, lvl: ActionsLog::NOTICE, o_id: self.o_id).save
        return true
      end
    end
    return false
  end

  def cancel
    DB.transaction do
      items = self.items
      items.each { |item| item.dissociate @values[:o_id]}
      remove_all_items
      @values[:o_status] = Order::VOID
      save columns: [:o_id, :type, :o_status, :o_loc, :o_dst, :u_id, :created_at]
      current_user_id =  User.new.current_user_id
      current_location = User.new.current_location[:name]
      message = R18n.t.order.void
      ActionsLog.new.set(msg: message, u_id: current_user_id, l_id: current_location, lvl: ActionsLog::NOTICE, o_id: @values[:o_id]).save
      return true
    end
    return false
  end

  def non_destructive_cancel
    DB.transaction do
      items = self.items
      current_user_id =  User.new.current_user_id
      current_location = User.new.current_location[:name]
      items.each do |item|
        message = "Removiendo #{item.p_name} de la orden #{@values[:o_id]}"
        ActionsLog.new.set(msg: message, u_id: current_user_id, l_id: current_location, lvl: ActionsLog::NOTICE, o_id: @values[:o_id], i_id: item.i_id, p_id: item.p_id).save
        item.change_status Item::READY, @values[:o_id]
      end
      remove_all_items
      @values[:o_status] = Order::VOID
      save columns: Order::ATTRIBUTES
      message = R18n.t.order.void
      ActionsLog.new.set(msg: message, u_id: current_user_id, l_id: current_location, lvl: ActionsLog::NOTICE, o_id: @values[:o_id]).save
    end
  end

  def cancel_return
    DB.transaction do
      items = self.items
      current_user_id =  User.new.current_user_id
      current_location = User.new.current_location[:name]
      items.each do |item|
        message = "Removiendo #{item.p_name} de la orden #{@values[:o_id]}"
        ActionsLog.new.set(msg: message, u_id: current_user_id, l_id: current_location, lvl: ActionsLog::NOTICE, o_id: @values[:o_id], i_id: item.i_id, p_id: item.p_id).save
        item.change_status Item::SOLD, @values[:o_id]
      end
      remove_all_items
      @values[:o_status] = Order::VOID
      save columns: Order::ATTRIBUTES
      message = R18n.t.order.void
      ActionsLog.new.set(msg: message, u_id: current_user_id, l_id: current_location, lvl: ActionsLog::NOTICE, o_id: @values[:o_id]).save
      return true
    end
  end

  def create_new type
    u = User.new
    current_user_id = u.current_user_id
    current_location = u.current_location[:name]

    order = Order
    .filter(type: type)
    .filter(o_status: Order::OPEN, u_id: current_user_id, o_loc: current_location)
    .order(:created_at)
    .first
    if order.class ==  NilClass
      order = Order
      .create(type: type, o_status: Order::OPEN, u_id: current_user_id, o_loc: current_location)
      message = R18n.t.order.created(order.type)
      ActionsLog.new.set(msg: message, u_id: current_user_id, l_id: current_location, lvl:  ActionsLog::NOTICE, o_id: order.o_id).save
    end
    order
  end

  def create_invalidation origin
    current_user_id =  User.new.current_user_id
    order = Order.create(type: Order::INVALIDATION, o_status: Order::OPEN, u_id: current_user_id, o_loc: origin, o_dst: Location::VOID)
    message = R18n.t.order.created(order.type)
    ActionsLog.new.set(msg: message, u_id: current_user_id, l_id: origin, lvl:  ActionsLog::NOTICE, o_id: order.o_id).save
    order
  end

  def create_transmutation origin
    current_user_id =  User.new.current_user_id
    order = Order.create(type: Order::TRANSMUTATION, o_status: Order::OPEN, u_id: current_user_id, o_loc: origin, o_dst: Location::VOID)
    message = R18n.t.order.created(order.type)
    ActionsLog.new.set(msg: message, u_id: current_user_id, l_id: origin, lvl:  ActionsLog::NOTICE, o_id: order.o_id).save
    order
  end


  def create_samplification origin
    current_user_id =  User.new.current_user_id
    order = Order.create(type: Order::SAMPLIFICATION, o_status: Order::OPEN, u_id: current_user_id, o_loc: origin, o_dst: Location::VOID)
    message = R18n.t.order.created(order.type)
    ActionsLog.new.set(msg: message, u_id: current_user_id, l_id: origin, lvl:  ActionsLog::NOTICE, o_id: order.o_id).save
    order
  end


  def create_or_load_sale
    create_new Order::SALE
  end

  def recalculate_as( type )
    case type.to_sym
    when :Profesional
      message = "Aplicado descuento a profesionales"
      DB.transaction do
        items = self.items
        items.each do |item|
          item.i_price = Product[item.p_id].price_pro
          item.save
        end
      end
    when :Regular
      message = "Utilizando precios de lista"
      DB.transaction do
        items = self.items
        items.each do |item|
          item.i_price = Product[item.p_id].price
          item.save
        end
      end
    end
    message
  end

  def types_at_location location
    orders = Order.
      select(:type)
    .filter( Sequel.or(o_loc: location, o_dst: location) )
    .group(:type)
    .all
    types = []
    orders.each { |order| types << order.type}
    types
  end

  def sale_id
    @values[:sale_id]
  end

end
