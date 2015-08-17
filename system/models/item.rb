# coding: UTF-8
require 'sequel'
require_relative 'order'
require_relative '../helpers/sequel_binary'

class Item < Sequel::Model

  NEW         ="NEW"
  PRINTED     ="PRINTED"
  ASSIGNED    ="ASSIGNED"
  MUST_VERIFY ="MUST_VERIFY"
  VERIFIED    ="VERIFIED"
  READY       ="READY"
  IN_ASSEMBLY ="IN_ASSEMBLY"
  SALE        ="SALE"
  ON_CART     ="ON_CART"
  SOLD        ="SOLD"
  RETURNING   ="RETURNING"
  ERROR       ="ERROR"
  VOID        ="VOID"
  SAMPLE      ="SAMPLE"

  @sale_id = 666

  require_relative 'item_sql.rb'

  def hash
    p_id.hash
  end
  def eql? item
    self.p_id == item.p_id
  end

  def split_input_into_ids input
    ids = []
    input.split("\n").map { |id| ids << id.to_s.strip unless id.to_s.strip.empty?}
    ids
  end

  def check_io input, output
    return [] if input.count == output.count
    output.each { |item| input.delete(item.i_id)}
    input
  end

  def check_reason reason
    reason.strip!
    raise ArgumentError, "Es necesario especificar la razon para invalidar el item" if reason.length < 5
    reason
  end


  def check_product_for_transmutation p_id
    p_id = p_id.to_i
    product = Product[p_id]
    raise ArgumentError, R18n.t.product.missing(p_id) if product.nil?
    raise ArgumentError, R18n.t.product.errors.archived if product.archived
    product
  end


  def empty?
    return @values[:i_id].nil? ? true : false
  end

  def update_from item
    @values[:i_id] = item.i_id
    @values[:p_id] = item.p_id
    @values[:p_name] = item.p_name
    @values[:i_price] = item.i_price
    @values[:i_price_pro] = item.i_price_pro
    @values[:i_status] = item.i_status
    @values[:i_loc] = item.i_loc
    @values[:created_at] = item.created_at
    @values[:updated_at] = item.updated_at

    @sale_id = item[:sale] if item[:sale]
    @sale_id ||= item.o_id if item.o_id
    self
  end

  def sale_id
    @sale_id
  end

  def o_id
    @values[:o_id]
  end


  def void! reason
    reason = check_reason reason
    begin
      DB.transaction do
        self.orders.dup.each do |order|
          order.remove_item self unless order.o_status == Order::VOID || order.o_status == Order::FINISHED || self.i_status == Item::IN_ASSEMBLY
        end
      end
      change_status_security_check Item::VOID, 0
    rescue SecurityError => e
      raise SecurityError, e.message
    end
    order = Order.new.create_invalidation self.i_loc
    origin = @values[:i_loc].dup
    @values[:i_loc] = Location::VOID
    @values[:i_status] = Item::VOID
    order.add_item self
    save validate: false

    current_user_id =  User.new.current_user_id
    message = "#{R18n.t.actions.changed_item_status(ConstantsTranslator.new(Item::VOID).t)}. Razon: #{reason}"
    log = ActionsLog.new.set(msg: message, u_id: current_user_id, l_id: origin, lvl: ActionsLog::NOTICE, i_id: @values[:i_id], o_id: order.o_id)
    log.set(p_id: @values[:p_id]) unless @values[:p_id].nil?
    log.save

    product = Product[self.p_id]
    product.update_stocks.save unless product.nil?

    order.change_status Order::FINISHED
    message
  end

  def samplify!
    begin
      DB.transaction do
        self.orders.dup.each do |order|
          order.remove_item self unless order.o_status == Order::VOID || order.o_status == Order::FINISHED || self.i_status == Item::IN_ASSEMBLY
        end
      end
      change_status_security_check Item::SAMPLE, 0
    rescue SecurityError => e
      raise SecurityError, e.message
    end
    order = Order.new.create_samplification self.i_loc
    origin = @values[:i_loc].dup
    @values[:i_status] = Item::SAMPLE
    order.add_item self
    save validate: false

    current_user_id =  User.new.current_user_id
    message = "#{R18n.t.actions.changed_item_status(ConstantsTranslator.new(Item::SAMPLE).t)}."
    log = ActionsLog.new.set(msg: message, u_id: current_user_id, l_id: origin, lvl: ActionsLog::NOTICE, i_id: @values[:i_id])
    log.set(p_id: @values[:p_id]) unless @values[:p_id].nil?
    log.save

    product = Product[self.p_id]
    product.update_stocks.save unless product.nil?

    order.change_status Order::FINISHED
    message
  end

  def change_status_security_check status, o_id
    if self.i_status == Item::VOID
      current_user_id =  User.new.current_user_id
      current_location = User.new.current_location[:name]
      message = R18n.t.errors.modifying_status_of_void_item(@values[:i_id])
      log = ActionsLog.new.set(msg: message, u_id: current_user_id, l_id: current_location, lvl: ActionsLog::ERROR, i_id: @values[:i_id])
      log.set(o_id: o_id) unless o_id == 0
      log.save
      raise SecurityError, message
    end
    if @values[:p_id].nil? and not @values[:i_status] == Item::NEW and not status == Item::VOID
      current_user_id =  User.new.current_user_id
      current_location = User.new.current_location[:name]
      message = R18n.t.errors.modifying_status_of_nil_product_item(@values[:i_id])
      log = ActionsLog.new.set(msg: message, u_id: current_user_id, l_id: current_location, lvl: ActionsLog::ERROR, i_id: @values[:i_id])
      log.set(o_id: o_id) unless o_id == 0
      log.save
      raise SecurityError, message
    end
  end

  def change_status status, o_id
    o_id = o_id.to_i
    change_status_security_check status, o_id
    @values[:i_status] = status
    save columns: [:p_id, :p_name, :i_price, :i_price_pro, :i_status, :i_loc]
    current_user_id =  User.new.current_user_id
    current_location = User.new.current_location[:name]
    message = R18n.t.actions.changed_item_status(ConstantsTranslator.new(status).t)
    log = ActionsLog.new.set(msg: message, u_id: current_user_id, l_id: current_location, lvl: ActionsLog::INFO, i_id: @values[:i_id])
    log.set(o_id: o_id) unless o_id == 0
    log.set(p_id: @values[:p_id]) unless @values[:p_id].nil?
    log.save

    product = Product[self.p_id]
    product.update_stocks.save unless product.nil?

    message
  end

  def i_loc= location
    @values[:i_loc] = location
  end

  def inStore
    if (@values[:i_loc] == Location::S1 || @values[:i_loc] == Location::S2)
      true
    else
      false
    end
  end

  def print
    out     = "\n"
    out     += "#{self.class} #{sprintf("%x", self.object_id)}:\n"
    out     += "\ti_id:  #{self.i_id}\n"
    out     += "\tp_id:  #{self.p_id}\n"
    out     += "\tp_name:  #{self.p_name}\n"
    out     += self.i_price ? "\ti_price: #{sprintf("%0.2f", self.i_price)}\n" : "\ti_price: \n"
    out     += self.i_price_pro ? "\ti_price_pro: #{sprintf("%0.2f", self.i_price_pro)}\n" : "\ti_price_pro: \n"
    out     += "\ti_status: #{self.i_status}\n"
    out     += "\ti_loc: #{self.i_loc}\n"
    created = self.created_at ? Utils::local_datetime_format(self.created_at) : ""
    out     += "\tcreated: #{created}\n"
    puts out
  end

  def validate
    super

    validates_schema_types [:i_id, :i_id]
    validates_schema_types [:p_id, :p_id]
    validates_schema_types [:i_price, :i_price]
    validates_schema_types [:i_price_pro, :i_price_pro]
    validates_schema_types [:i_status, :i_status]
    validates_schema_types [:created_at, :created_at]
    validates_schema_types [:updated_at, :updated_at]

    validates_exact_length 12, :i_id, message: "Id inválido #{@values[:i_id]}"
    validates_presence [:p_name, :i_status], message: "No esta asignado"

    if i_status != Item::NEW && i_status != Item::PRINTED
      if p_id.class != Fixnum
        errors.add("p_id", "Debe ser numérico. #{p_id} (#{p_id.class}) dado" )
      else
        errors.add("p_id", "Debe ser positivo. #{p_id} dado" ) unless p_id > 0
      end
    end

    if (i_price.class != BigDecimal) && (i_price.class != Fixnum)
      errors.add("Precio", "Debe ser numérico. #{i_price} (#{i_price.class}) dado" )
    elsif i_price < 0
      num = i_price.class == BigDecimal ? i_price.round(3).to_s("F") :  i_price
      errors.add("Precio", "Debe ser positivo o cero. #{num} dado" )
    end

    if (i_price_pro.class != BigDecimal) && (i_price_pro.class != Fixnum)
      errors.add("Precio", "Debe ser numérico. #{i_price_pro} (#{i_price_pro.class}) dado" )
    elsif i_price_pro < 0
      num = i_price_pro.class == BigDecimal ? i_price_pro.round(3).to_s("F") :  i_price_pro
      errors.add("Precio", "Debe ser positivo o cero. #{num} dado" )
    end

  end



end
