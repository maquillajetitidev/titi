# coding: utf-8
require 'sequel'

class BookRecord < Sequel::Model(:book_records)

  DOWNPAYMENTS = "Pago a proveedor"
  EXPENSES = "Otros gastos"
  COLLECTION = "Recaudacion"
  CASH_DEFICIT = "Faltante de caja"
  COMMISSIONS = "Comisiones"

  CASH_SURPLUS = "Sobrante de caja"
  STARTING_CASH = "Caja inicial"
  OTC_SALE = "Venta mostrador"

  MINUS = [DOWNPAYMENTS, EXPENSES, COLLECTION, CASH_DEFICIT, COMMISSIONS]
  PLUS = [CASH_SURPLUS, STARTING_CASH, OTC_SALE]

  def update_from_hash(hash_values)
    raise ArgumentError, t.errors.nil_params if hash_values.nil?
    wanted_keys = [ :amount, :type, :description ]
    hash_values.select { |key, value| self[key.to_sym]=value.to_s.gsub(',', '.') if wanted_keys.include? key.to_sym unless value.nil?}
    cast
    self
  end

  def validate
    super

    validates_schema_types [:amount, :amount]
    validates_schema_types [:type, :type]
    validates_schema_types [:description, :description]

    if amount.nil? or amount == 0
      errors.add("El monto", "no puede ser cero" )
    elsif amount.class != BigDecimal
      errors.add("El monto", "debe ser numérico. #{amount} (#{amount.class}) dado" )
    end
    errors.add("El tipo de movimiento", "no puede estar vacio" ) if type.empty?

  end



  def get_last_cash_audit_id location
    BookRecord
      .select{max(:r_id).as(last_audit)}
      .where(type: "Caja inicial")
      .where(b_loc: location)
      .first[:last_audit]
  end

  def get_last_cash_audit location
    r_id = get_last_cash_audit_id location
    BookRecord[r_id]
  end

  def from_last_audit location
    r_id = get_last_cash_audit_id(location)
    BookRecord
      .where{Sequel.expr(:r_id) >= r_id}
  end

  def from_date_with_interval location, date, interval
    # interval = {days: 1}
    # select * from book_records where created_at >= "2007-07-20" and created_at < date_add("2007-07-20", interval 1 day);
    date = Date.parse date
    art_date = "#{date.iso8601} 03:00"
    add = Sequel.date_add(art_date, interval)
    records = BookRecord.where{Sequel.expr(:created_at) >= art_date}.where{Sequel.expr(:created_at) < add}
  end

  private
    def cast
      unless self[:amount].nil? or self[:amount] == 0
        self[:amount] = BigDecimal.new(self[:amount]).abs
        self[:amount] *= -1 if BookRecord::MINUS.include?(self[:type])
      end
    end
end

