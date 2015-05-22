require 'sequel'

class Assembly_order_to_product < Sequel::Model(:assembly_orders_to_products)

  def create o_id, p_id
    order_to_product = Assembly_order_to_product.create(o_id: o_id, p_id: p_id)
    current_user_id =  User.new.current_user_id
    current_location = User.new.current_location[:name]
    message = R18n.t.order.assembly_relation_created(o_id, p_id)
    ActionsLog.new.set(msg: message, u_id: current_user_id, l_id: current_location, lvl:  ActionsLog::NOTICE, o_id: o_id, p_id: p_id).save
    order_to_product
  end
end

class Order < Sequel::Model
  many_to_many :items, class: :Item, join_table: :line_items, left_key: :o_id, right_key: :i_id
  many_to_many :bulks, class: :Bulk, join_table: :line_bulks, left_key: :o_id, right_key: :b_id

  #type
  PACKAGING="PACKAGING"
  ASSEMBLY="ASSEMBLY"
  INVENTORY="INVENTORY"
  WH_TO_POS="WH_TO_POS"
  POS_TO_WH="POS_TO_WH"
  WH_TO_WH="WH_TO_WH"
  SALE="SALE"
  RETURN="RETURN"
  CREDIT_NOTE="CREDIT_NOTE"
  INVALIDATION="INVALIDATION"
  TRANSMUTATION ="TRANSMUTATION"
  SAMPLIFICATION="SAMPLIFICATIO"
  TYPES = [PACKAGING, ASSEMBLY, INVENTORY, WH_TO_POS, POS_TO_WH, WH_TO_WH, SALE, INVALIDATION, TRANSMUTATION, RETURN, CREDIT_NOTE]
  PRODUCTION_TYPES = [PACKAGING, ASSEMBLY, WH_TO_POS, WH_TO_WH]

  # status
  OPEN="OPEN"
  MUST_VERIFY="MUST_VERIFY"
  VERIFIED="VERIFIED"
  FINISHED="FINISHED"
  USED="USED"
  EN_ROUTE="EN_ROUTE"
  VOID="VOID"

  # actions
  ALLOCATION="ALLOCATION"
  VERIFICATION = "VERIFICATION"
  PRODUCTION_ACTIONS = [PACKAGING, ASSEMBLY, VERIFICATION, ALLOCATION, ]

  ATTRIBUTES = [:o_id, :type, :o_status, :o_loc, :u_id, :created_at]
  # same as ATTRIBUTES but with the neccesary table references for get_ functions
  COLUMNS = [:orders__o_id, :type, :o_status, :o_loc, :u_id, :orders__created_at]

  def get_assembly_meta
    Assembly_order_to_product.where(o_id: self.o_id).first
  end
  def get_assembly
    assy = get_assembly_meta
    return assy.nil? ? Product.new : Product.new.get(assy.p_id)
  end
  def set_assembly_id i_id
    assy = get_assembly_meta
    assy.i_id = i_id
    assy.save
  end

  def items
    Item
      .select_group(*Item::COLUMNS)
      .join(:line_items, line_items__i_id: :items__i_id, o_id: self.o_id)
      .order(:p_name)
      .all
  end

  def bulks
    Bulk
      .select_group(*Bulk::COLUMNS, :materials__m_name)
      .join(:line_bulks, line_bulks__b_id: :bulks__b_id, o_id: self.o_id)
      .join(:materials, materials__m_id: :bulks__m_id)
      .order(:m_name)
      .all
  end

  def materials
    materials = Material
    .select(:materials__m_id, :m_name, :c_id)
    .select_append(:c_name)
    .join(:products_materials, [:m_id])
    .join(:products, products__p_id: :products_materials__product_id)
    .join(:items, [:p_id])
    .join(:line_items, line_items__i_id: :items__i_id, o_id: self.o_id)
    .join(:materials_categories, materials_categories__c_id: :materials__c_id)
    .select_group(:m_id, :m_name, :c_name, :materials__c_id)
    .select_append{sum(:m_qty).as(m_qty)}
    .order(:m_name)
    .all
    materials.each do |mat|
      mat[:m_qty] = BigDecimal.new(mat[:m_qty], 3)
    end
    materials
  end

  def create type
    current_user_id =  User.new.current_user_id
    current_location = User.new.current_location[:name]
    order = Order.create(type: type, o_status: Order::OPEN, u_id: current_user_id, o_loc: current_location )
    order = Order[order.o_id]
    message = R18n.t.order.created(order.type)
    ActionsLog.new.set(msg: message, u_id: current_user_id, l_id: current_location, lvl:  ActionsLog::NOTICE, o_id: order.o_id).save
    order
  end

  def create_or_load type
    current_user_id =  User.new.current_user_id
    current_location = User.new.current_location[:name]
    order = Order
              .filter(type: type)
              .filter(o_status: Order::OPEN, u_id: current_user_id, o_loc: current_location )
              .order(:created_at)
              .first
    order = self.create type if order.nil?
    order
  end

  def create_or_load_return_for_sale sale_id
    return_order = create_or_load Order::RETURN
    return_order.create_or_load_return_association sale_id
    return_order
  end

  def create_or_load_return_association sale_id
    if self.type == Order::RETURN
      str = SalesToReturn.filter(:return=>self.o_id).first
      str = SalesToReturn.new.set_all(sale: sale_id, :return=>self.o_id).save if str.nil?
      raise ArgumentError, R18n::t.errors.sale_id_missmatch unless str.sale == sale_id
      @values[:sale_id] = str.sale
    end
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

  def get o_id
    order = get_orders
              .where(o_id: o_id.to_i)
              .first
    return order.nil? ? Order.new : order
  end

  def get_orders
    Order
      .select(:o_id, :o_code, :type, :o_status, :o_loc, :o_dst, :orders__created_at, :u_id, :username)
      .join(:users, user_id: :u_id)
  end


  def get_orders_at_location location
    get_orders
      .filter( Sequel.or(o_loc: location.to_s, o_dst: location.to_s) )
  end

  def get_orders_at_destination location
    get_orders
      .filter( o_dst: location.to_s)
  end

  def get_orders_with_type type
    get_orders
      .filter(type: type)
  end

  def get_orders_with_type_status_and_code type, o_status, o_code
    order = get_orders
      .filter(type: type)
      .filter(o_status: o_status)
      .filter(o_code: remove_dash_from_code(o_code.to_s))
      .first
    if order.nil?
      order = Order.new
      order.errors.add R18n.t.errors.inexistent_order.to_s, R18n.t.errors.invalid_order_id.to_s
    end
    order
  end

  def get_orders_at_location_with_type location, type
    get_orders_at_location(location)
      .filter(type: type)
  end

  def get_orders_at_location_with_type_and_status location, type, o_status
    get_orders_at_location_with_type( location, type)
      .filter( o_status: o_status)
  end

  def get_orders_at_destination_with_type_and_status location, type, o_status
    get_orders_at_destination( location )
      .filter(type: type)
      .filter( o_status: o_status)
  end

  def get_orders_at_location_with_type_status_and_id location, type, o_status, o_id
    o_id = o_id.to_i
    get_orders_at_location_with_type_and_status( location, type, o_status)
      .filter(o_id: o_id)
      .first
  end

  def get_orders_at_location_with_type_status_and_code location, type, o_status, o_code
    return Order.new if o_code.nil?
    o_code = o_code.to_s.strip
    order = get_orders_at_location_with_type_and_status( location, type, o_status)
      .filter(o_code: remove_dash_from_code(o_code.to_s))
      .first
    if order.nil?
      order = Order.new
      order.errors.add R18n.t.errors.inexistent_order.to_s, R18n.t.errors.invalid_order_id.to_s
    end
    order
  end

  def get_orders_at_location_with_type_and_id location, type, o_id
    get_orders_at_location_with_type(location, type)
      .filter(o_id: o_id)
      .first
  end

  def get_packaging_orders
    get_orders_with_type Order::PACKAGING
  end

  def get_packaging_orders_in_location location
    get_orders_at_location_with_type location, Order::PACKAGING
  end

  def get_packaging_order o_id, location
    order = get_packaging_orders_in_location(location)
      .filter(o_id: o_id.to_i)
      .filter(o_status: [Order::OPEN, Order::MUST_VERIFY])
      .first
    if order.class == Order
      return order
    else
      current_user_id =  User.new.current_user_id
      current_user_name =  User.new.current_user_name
      current_location = User.new.current_location[:name]
      message = R18n.t.order.user_is_editing_nil(current_user_name, Order::PACKAGING, o_id)
      ActionsLog.new.set(msg: message, u_id: current_user_id, l_id: current_location, lvl: ActionsLog::ERROR).save
      return Order.new
    end
  end

  def get_open_packaging_orders location
    get_packaging_orders_in_location(location)
      .filter(o_status: Order::OPEN)
  end

  def get_unverified_packaging_orders location
    get_packaging_orders_in_location(location)
      .filter(o_status: Order::MUST_VERIFY)
  end

  def get_packaging_order_for_verification o_id, location, log=true
    order = get_packaging_orders_in_location(location)
      .filter(o_status: Order::MUST_VERIFY)
      .filter(o_id: o_id.to_i)
      .first
    current_user_id =  User.new.current_user_id
    current_user_name =  User.new.current_user_name
    current_location = User.new.current_location[:name]
    if order.class == Order
      if order.type == Order::PACKAGING
        if order.o_status == Order::MUST_VERIFY
          message = R18n.t.order.user_is_verifying(current_user_name, order.type, order.o_id)
          ActionsLog.new.set(msg: message, u_id: current_user_id, l_id: current_location, lvl: ActionsLog::NOTICE, o_id: order.o_id).save if log
          return order
        else
          message = R18n.t.order.user_is_verfying_order_in_invalid_status(current_user_name, order.type, order.o_id, order.o_status)
          ActionsLog.new.set(msg: message, u_id: current_user_id, l_id: current_location, lvl: ActionsLog::ERROR, o_id: order.o_id).save
          order = Order.new
          order.errors.add("", message)
          return order
        end
      else
        message = R18n.t.order.user_is_verfying_order_of_wrong_type(current_user_name, order.o_id, order.o_status, order.type)
        ActionsLog.new.set(msg: message, u_id: current_user_id, l_id: current_location, lvl: ActionsLog::ERROR, o_id: order.o_id).save
        order = Order.new
        order.errors.add("", message)
        return order
      end
    else
      order = Order.new
      message = R18n.t.order.user_is_editing_nil(current_user_name, Order::PACKAGING, o_id)
      ActionsLog.new.set(msg: message, u_id: current_user_id, l_id: current_location, lvl: ActionsLog::ERROR).save
      order = Order.new
      order.errors.add("", message)
      return order
    end
  end

  def get_verified_packaging_orders location
    get_packaging_orders_in_location(location)
      .filter(o_status: Order::VERIFIED)
  end

  def get_order_for_allocation o_id, location
    get_packaging_orders
      .filter(o_status: Order::VERIFIED)
      .filter(o_id: o_id.to_i)
      .filter( Sequel.or(o_loc: location.to_s, o_dst: location.to_s) )
      .first
  end

  def get_wh_to_pos
    get_orders
      .filter(type: Order::WH_TO_POS)
  end

  def get_wh_to_pos__open location
    get_wh_to_pos
      .filter( Sequel.or(o_loc: location.to_s, o_dst: location.to_s) )
      .filter(o_status: Order::OPEN)
  end

  def get_wh_to_pos__open_by_id o_id, location
    get_wh_to_pos
      .filter( Sequel.or(o_loc: location.to_s, o_dst: location.to_s) )
      .filter(o_id: o_id.to_i)
  end

  def get_wh_to_pos__en_route destination
    get_wh_to_pos
      .filter(o_dst: destination.to_s)
      .filter(o_status: Order::EN_ROUTE)
  end

  def get_wh_to_pos__en_route_by_id destination, o_id
    get_wh_to_pos__en_route(destination)
      .filter(o_id: o_id.to_i)
      .first
  end

  def get_inventory_imputation
    get_orders
      .filter(type: Order::INVENTORY)
      .filter(o_status: Order::VERIFIED)
      .order(:o_id).reverse
  end

  def items_as_cart
    Item
      .select_group(:p_id, :p_name, :i_price, :i_price_pro)
      .select_append{sum(1).as(qty)}
      .join(:line_items, line_items__i_id: :items__i_id)
      .join(:orders, line_items__o_id: :orders__o_id, orders__o_id: @values[:o_id])
  end

  def detailed_items_as_cart
    Item
      .select_group(:items__i_id, :p_id, :p_name, :i_price, :i_price_pro)
      .select_append( Sequel.as(Sequel.lit("1"), :qty) )
      .join(:line_items, line_items__i_id: :items__i_id)
      .join(:orders, line_items__o_id: :orders__o_id, orders__o_id: @values[:o_id])
  end

  def cart_total
    cart_total = Item
      .select{sum(:i_price).as(total)}
      .join(:line_items, line_items__i_id: :items__i_id)
      .join(:orders, line_items__o_id: :orders__o_id, orders__o_id: @values[:o_id])
      .first[:total]
    return cart_total.nil? ? 0 : cart_total
  end

  def credit_total
    credit_total = Credit_note
      .select{abs(sum(:cr_ammount)).as(total)}
      .filter(o_id: self.o_id)
      .first[:total]
    return credit_total.nil? ? 0 : credit_total
  end

  def credits
    Credit_note
      .select(*Credit_note::COLUMNS)
      .join(:orders, [:o_id])
      .where(credit_notes__o_id: self.o_id)
      .all
  end

  def payments
    Line_payment
      .join(:orders, [:o_id])
      .where(line_payments__o_id: self.o_id)
      .all
  end

  def payments_total
    payments_total = Line_payment
      .select{abs(sum(:payment_ammount)).as(total)}
      .filter(o_id: self.o_id)
      .first[:total]
    if payments_total.nil?
      payments_total = 0
      BookRecord.where(o_id: self.o_id).all.each { |payment| payments_total += payment.amount }
    end
    return payments_total.nil? ? 0 : payments_total
  end

  def payment_type
    pro_sum = 0
    self.items.each { |item| pro_sum =+ item.i_price_pro }
    return payments_total == pro_sum ? "profesional" : "normal"
  end
end
