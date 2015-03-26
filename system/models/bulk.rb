# coding: utf-8
require 'sequel'
require_relative 'material'
require_relative '../helpers/sequel_binary'

class Bulk < Sequel::Model
  many_to_one :material, key: :m_id

  UNDEFINED="UNDEFINED"
  MUST_VERIFY="MUST_VERIFY"
  VERIFIED="VERIFIED"
  NEW="NEW"
  IN_USE="IN_USE"
  EMPTY="EMPTY"
  ERROR="ERROR"
  VOID="VOID"
  STATUS = [UNDEFINED, NEW, IN_USE, VOID]
  SELECTABLE_STATUS = [NEW, IN_USE]

  ATTRIBUTES = [:b_id, :m_id, :b_qty, :b_price, :b_status, :b_printed, :b_loc, :created_at]
  # same as ATTRIBUTES but with the neccesary table references for get_ functions
  COLUMNS = [:bulks__b_id, :bulks__m_id, :b_qty, :b_price, :b_status, :b_printed, :b_loc, :bulks__created_at]

  def location
    b_loc
  end

  def save (opts=OPTS)
    opts = opts.merge({columns: Bulk::ATTRIBUTES})
    begin
      super opts
    rescue => message
      errors.add "General", message
    end
    self
  end

  def empty?
    return @values[:b_id].nil? ? true : false
  end

  def missing b_id
    if Bulk[b_id].nil?
      errors.add("Bulk invalido", "No tengo ningun granel con el id #{b_id}")
      return true
    end
    return false
  end

  def has_been_void
    if @values[:b_status] == Bulk::VOID
      errors.add("Bulk invalido", "Este bulk fue Invalidado. No podes operar sobre el.")
      return true
    end
    return false
  end

  def has_been_verified
    if @values[:b_status] == Bulk::VERIFIED
      errors.add("Error de usuario", "Este granel ya fue verificado anteriormente.")
      return true
    end
    return false
  end

  def is_from_another_location
    if @values[:b_loc] != User.new.current_location[:name]
      errors.add("Bulk fuera de lugar", "Este granel pertenece a \"#{ConstantsTranslator.new(@values[:b_loc]).t}\". Ni siquiera deberia estar aqui.")
      return true
    end
    return false
  end

  def is_from_current_location
    if @values[:b_loc] == User.new.current_location[:name]
      errors.add("Bulk fuera de lugar", "Estas intentando mover un granel desntro del mismo deposito")
      return true
    end
    return false
  end

  def last_order
    Order
      .select(:orders__o_id, :type, :o_status, :o_loc, :u_id, :orders__created_at)
      .join(:line_bulks, line_bulks__o_id: :orders__o_id)
      .join(:bulks, line_bulks__b_id: :bulks__b_id, line_bulks__b_id: @values[:b_id])
      .order(:o_id)
      .last
  end

  def is_on_some_order o_id
    return false if @values[:b_status] != Bulk::MUST_VERIFY and @values[:b_status] != Bulk::VERIFIED
    last = last_order
    errors.add("Error de carga", "Este granel ya fue agregado a la orden actual con anterioridad.") if last.o_id == o_id
    errors.add("Error de carga", "Este granel pertenece a la orden. #{last.o_id}") if last.o_id != o_id
    return true
  end

  def update_from bulk
    @values[:b_id] = bulk.b_id
    @values[:m_id] = bulk.m_id
    @values[:b_qty] = bulk.b_qty
    @values[:b_status] = bulk.b_status
    @values[:b_loc] = bulk.b_loc
    @values[:created_at] = bulk.created_at
    self
  end

  def get_for_transport b_id, o_id
    b_id = b_id.to_s.strip
    bulk = Bulk.left_join(:materials, [:m_id]).filter(b_status: Bulk::SELECTABLE_STATUS, b_loc: User.new.current_location[:name], b_id: b_id).first
    return bulk unless bulk.nil?
    return self if missing(b_id)
    update_from Bulk[b_id]
    return self if has_been_void
    return self if is_from_another_location
    return self if is_on_some_order o_id
    errors.add("Error inesperado", "Que hacemos?")
    return self
  end

  def get_for_verification b_id, o_id
    b_id = b_id.to_s.strip
    bulk = Bulk.left_join(:materials, [:m_id]).filter(b_status: Bulk::MUST_VERIFY, b_id: b_id).first
    return bulk unless bulk.nil?
    return self if missing(b_id)
    update_from Bulk[b_id]
    return self if has_been_void
    return self if has_been_verified
    return self if is_from_current_location
    errors.add("Error inesperado", "Que hacemos?")
    return self
  end

  def get_for_removal b_id, o_id
    b_id = b_id.to_s.strip
    bulk = Bulk.left_join(:materials, [:m_id]).filter(b_loc: User.new.current_location[:name], b_id: b_id).join(:line_bulks, [:b_id]).filter(o_id: o_id).first
    return bulk unless bulk.nil?
    return self if missing(b_id)
    update_from Bulk[b_id]
    return self if has_been_void
    return self if is_from_another_location
    return self if is_on_some_order o_id
    errors.add("Error inesperado", "Que hacemos?")
    return self
  end


  def get_bulks_in_orders
    Bulk
      .left_join(:materials, [:m_id])
      .join(:line_bulks, [:b_id])
      .join(:orders, [:o_id])
      .select(:b_id, :b_qty, :b_price, :b_status, :b_printed, :bulks__created_at, :b_loc )
      .select_append{:m_name}
      .order(:m_name, :bulks__created_at)
  end

  def get_bulks_in_orders_for_location location
    get_bulks_in_orders
      .filter(o_dst: location)
  end

  def get_bulks_in_orders_for_location_and_status location, b_status
    get_bulks_in_orders_for_location(location)
      .filter(b_status: b_status)
  end

  def get_bulks_at_location location
    begin
      Bulk.select(:b_id, :b_qty, :b_price, :b_status, :b_printed, :bulks__created_at, :b_loc )
          .left_join(:materials, [:m_id])
          .select_append{:m_name}
          .where(b_loc: location)
          .order(:m_name, :bulks__created_at)
    rescue Exception => @e
      p @e
      return []
    end
  end

  def get_bulks_at_location_with_status location, status
    get_bulks_at_location(location)
      .filter(b_status: status.to_s)
  end

  def create m_id, b_price, location
    b_price = BigDecimal.new b_price, 3
    DB.transaction do
      bulk = Bulk.new
      bulk[:m_id] = m_id.to_i
      bulk[:b_price] = sprintf("%0.#{3}f", b_price.round(3))
      bulk[:b_loc] = location
      bulk[:b_status] = Bulk::NEW
      bulk.save validate: false
      last_b_id = DB.fetch( "SELECT @last_b_id" ).first[:@last_b_id]
      current_user_id =  User.new.current_user_id
      current_location = User.new.current_location[:name]
      message = R18n.t.bulk.created
      ActionsLog.new.set(msg: message, u_id: current_user_id, l_id: current_location, lvl: ActionsLog::INFO, b_id: last_b_id, m_id: m_id).save
      bulk[:b_id] = last_b_id
      bulk
    end
  end

  def get_by_id b_id
    begin
      Bulk.select(:b_id, :b_qty, :b_price, :b_status, :b_printed, :bulks__created_at )
          .left_join(:materials, [:m_id])
          .select_append{:m_name}
          .where(b_id: b_id)
          .first
    rescue Exception => @e
      p @e
      return [""]
    end
  end

  def get_unprinted location
    Bulk.select(:b_id, :m_id, :b_qty, :b_price, :b_status, :b_printed, :b_loc, :bulks__created_at)
      .left_join(:materials, [:m_id])
      .select_append{:m_name}
      .filter(b_printed: 0)
      .filter(b_loc: location.to_s)
      .order(:m_id)
  end

  def raise_if_changing_void current_user_id, current_location
    if @values[:b_status] == Bulk::VOID
      message = R18n.t.errors.modifying_status_of_void_bulk(@values[:b_id])
      ActionsLog.new.set(msg: message, u_id: current_user_id, l_id: current_location, lvl: ActionsLog::ERROR, m_id: @values[:m_id], b_id: @values[:b_id]).save
      raise message
    end
  end

  def change_status status, o_id
    o_id = o_id.to_i
    u = User.new
    current_user_id = u.current_user_id
    current_location = u.current_location[:name]
    raise_if_changing_void current_user_id, current_location

    @values[:b_status] = status
    @values[:b_loc] = Location::UNDEFINED if status == Bulk::VOID
    save validate: false, columns: [:b_loc, :b_status]
    log = ActionsLog.new.set(msg: R18n.t.actions.changed_bulk_status(ConstantsTranslator.new(status).t), u_id: current_user_id, l_id: current_location, lvl: ActionsLog::INFO, m_id: @values[:m_id], b_id: @values[:b_id])
    log.set(o_id: o_id) unless o_id == 0
    log.save
    self
  end

  def set_as_printed
    u = User.new
    current_user_id = u.current_user_id
    current_location = u.current_location[:name]
    raise_if_changing_void current_user_id, current_location

    @values[:b_printed] = 1
    save validate: false, columns: [:b_printed]
    message = "Granel marcado como impreso"
    log = ActionsLog.new.set(msg: message, u_id: current_user_id, l_id: current_location, lvl: ActionsLog::INFO, m_id: @values[:m_id], b_id: @values[:b_id])
    log.save
    self
  end

  def get_as_csv location
    labels = get_unprinted(location).all
    DB.transaction do
      labels.each { |label| label.set_as_printed }
    end
    out = ""
    labels.each do |label|
      out += sprintf "\"#{label.b_id}\",\"#{label[:m_name]} (x #{Utils::number_format(label[:b_qty], 0)})\",\"Vto: #{(label.created_at+3.years).strftime("%b %Y")}\"\n"
    end
    out
  end

  def update_from_hash(hash_values)
    raise ArgumentError, t.errors.nil_params if hash_values.nil?
    wanted_keys = [ :b_qty, :b_status ]
    hash_values.select { |key, value| self[key.to_sym]=value.to_s.gsub(',', '.') if wanted_keys.include? key.to_sym unless value.nil?}
    if (BigDecimal.new self[:b_qty]) < 0.01
      self[:b_qty] = 0
      self[:b_status] = Bulk::EMPTY
    end
    cast
    self
  end

  def validate
    super

    validates_schema_types [:b_id, :b_id]
    validates_schema_types [:m_id, :m_id]
    validates_schema_types [:b_qty, :b_qty]
    validates_schema_types [:b_status, :b_status]
    validates_schema_types [:created_at, :created_at]

    validates_exact_length 13, :b_id, message: "Malformed id #{b_id}"

    if self[:b_qty] == 0 and self[:b_status] != Bulk::EMPTY
      change_status(Bulk::EMPTY, nil)
    end
    if m_id.class != Fixnum
      errors.add("ID", "Debe ser numérico. #{m_id} (#{m_id.class}) dado" )
    else
      errors.add("ID", "Debe ser positivo. #{m_id} dado" ) unless m_id > 0
    end

    if b_qty.class != BigDecimal
      errors.add("Cantidad", "Debe ser numérico. #{b_qty} (#{b_qty.class}) dado. Intentando editar el bulk #{b_id}" )
    else
      errors.add("Cantidad", "Debe ser positivo o cero. #{b_qty.round(3).to_s("F")} dado. Intentando editar el bulk #{b_id}" ) if b_qty < 0
    end
  end

  def print
    out = "\n"
    out += "#{self.class} #{sprintf("%x", self.object_id)}:\n"
    out += "\tb_id:    #{@values[:b_id]}\n"
    out += "\tm_id:  #{@values[:m_id]}\n"
    out += @values[:b_qty]   ? "\tb_qty:   #{sprintf("%d", @values[:b_qty])}\n"      : "\tb_qty: \n"
    out += "\tstatus: #{@values[:b_status]}\n"
    out += "\tb_loc: #{@values[:b_loc]}\n"
    out += "\tcreated: #{@values[:created_at]}\n"
    out
  end

  private
    def cast
      self[:b_qty] = BigDecimal.new self[:b_qty]
    end
end

