# coding: utf-8
require_relative 'bulk'

class MaterialCategory < Sequel::Model(:materials_categories)
  one_to_many :materials

  def empty?
    return !!!@values[:c_id]
  end

  def get_by_id c_id
     c_id = c_id.to_i
     category = MaterialCategory[c_id]
     category = MaterialCategory.new if category.nil?
     category
  end
end

# #################################################################################

class MaterialsCategory < Sequel::Model
  one_to_many :materials, key: :c_id
end

# #################################################################################


class Material < Sequel::Model(:materials)

  one_to_many :bulks, key: :m_id
  Material.nested_attributes :bulks

  many_to_one :MaterialCategory, key: :c_id
  many_to_many :products, left_key: :m_id, right_key: :product_id, join_table: :products_materials
  many_to_many :distributors , left_key: :m_id, right_key: :d_id, join_table: :materials_to_distributors

  ATTRIBUTES = [ :m_id, :c_id, :SKU, :m_name, :m_notes, :m_ideal_stock, :m_price, :created_at, :price_updated_at ]
  # same as ATTRIBUTES but with the needed table references for get_ functions
  COLUMNS = [ :materials__m_id, :c_id, :SKU, :m_name, :m_notes, :m_ideal_stock, :m_price, :materials__created_at, :materials__price_updated_at ]

  attr_reader :location
  def location= new_location
    @location= new_location
    self
  end

  def bulk
    begin
      Bulk.filter(m_id: @values[:m_id], b_loc: location).order(:b_status, :created_at).all
    rescue Exception => @e
      p @e
      return []
    end
  end


  def bulks warehouse_name
    begin
      Bulk.filter(m_id: @values[:m_id], b_loc: warehouse_name).order(:b_status, :created_at).all
    rescue Exception => @e
      p @e
      return []
    end
  end

  def bulks_global
    begin
      Bulk.filter(m_id: @values[:m_id]).order(:b_status, :created_at).all
    rescue Exception => @e
      p @e
      return []
    end
  end

  def category
    self.MaterialCategory
  end

  def d_name
    return "no data" if self[:distributors].nil?
    return "" if self[:distributors].empty?
    self[:distributors].first[:d_name]
  end

  def calculate_ideal_stock debug: false
    p "#{@values[:m_name]} (#{@values[:m_id]})" if debug
    total_needed = BigDecimal.new(0)
    products = self.products
    products.each do |product|
      materials = product.materials
      materials.each do |p_material|
        needed = (product[:archived] or product[:end_of_life]) ? BigDecimal.new(0) : (p_material[:m_qty] * product.direct_ideal_stock)
        p "  #{product.p_name} (#{product.p_id}): #{p_material[:m_qty].to_s("F")} x #{product.direct_ideal_stock.to_s("F")} = #{needed.to_s("F")}" if p_material.m_id == @values[:m_id] && debug
        total_needed += needed if p_material.m_id == @values[:m_id]
      end
    end
    p "Partial needed: #{total_needed.to_s("F")}" if debug
    products = Product.all
    products.each do |product|
      parts = product.parts
      parts.each do |product_part|
        materials = product_part.materials
        materials.each do |p_material|
          needed = (product[:archived] or product[:end_of_life]) ? BigDecimal.new(0) : p_material[:m_qty] * product_part[:part_qty] * product.direct_ideal_stock
          p "  #{product.p_name} (#{product.p_id}) -> #{product_part.p_name} (#{product_part.p_id}): #{p_material[:m_qty].to_s("F")} x #{product_part[:part_qty].to_s("F")} x #{product.direct_ideal_stock.to_s("F")} = #{needed.to_s("F")}" if p_material.m_id == @values[:m_id] && debug
          total_needed += needed if p_material.m_id == @values[:m_id]
        end
      end
    end
    p "Total needed: #{total_needed.to_s("F")}" if debug
    p "" if debug
    @values[:m_ideal_stock] = total_needed
    save columns: COLUMNS
    total_needed
  end

  def distributors
    return [] unless self.m_id.to_i > 0
    distributors = Distributor
                    .select_group(*Distributor::COLUMNS, *MaterialDistributor::COLUMNS)
                    .join(:materials_to_distributors, distributors__d_id: :materials_to_distributors__d_id, materials_to_distributors__m_id: self.m_id)
                    .order(:materials_to_distributors__mtd_id)
    return [] if distributors.nil?
    distributors
  end

  def get_by_sku sku
    sku.to_s.gsub(/\n|\r|\t/, '').squeeze(" ").strip
    material = Material.filter(sku: sku).first
    material ||= Material.new
    material
  end

  def products
    self.products_dataset.join(:categories, [:c_id]).select_append{:c_name}.order(:p_name).all
  end

  def save (opts=OPTS)
    # raise SecurityError, "#{State.current_user.username}: no tenes permisos para actualizar materiales" unless self.can_be_updated_by? State.current_user

    opts = opts.merge({columns: Material::COLUMNS})
    begin
      update_products = self.changed_columns.include? :m_price
      super opts
      if update_products
        current_user_id =  User.new.current_user_id
        message = "Actualizancion de costo de todos los productos que utilizan #{@values[:m_name]}"
        ActionsLog.new.set(msg: message, u_id: current_user_id, l_id: "GLOBAL", lvl: ActionsLog::NOTICE, m_id: @values[:m_id]).save
        self.products.each do |product|
          product.assemblies.each do |assy|
            assy.parts_cost
            assy.materials_cost
            assy.save
          end
          product.parts_cost
          product.materials_cost
          product.save
        end
      end
    rescue Sequel::UniqueConstraintViolation
      errors.add "SKU duplicado", "Ya existe un material con ese sku"
    end
    self
  end

  def update_stocks
    stock = Material
      .select{sum(:b_qty).as(stock_store_1)}
      .left_join(:bulks, materials__m_id: :bulks__m_id, b_loc: Location::S1)
      .where(materials__m_id: @values[:m_id])
      .first[:stock_store_1]
    stock ||= 0
    @values[:stock_store_1] = BigDecimal.new stock
    stock = Material
      .select{sum(:b_qty).as(stock_store_2)}
      .left_join(:bulks, materials__m_id: :bulks__m_id, b_loc: Location::S2)
      .where(materials__m_id: @values[:m_id])
      .first[:stock_store_2]
    stock ||= 0
    @values[:stock_store_2] = BigDecimal.new stock
    stock = Material
      .select{sum(:b_qty).as(stock_warehouse_1)}
      .left_join(:bulks, materials__m_id: :bulks__m_id, b_loc: Location::W1)
      .where(materials__m_id: @values[:m_id])
      .first[:stock_warehouse_1]
    stock ||= 0
    @values[:stock_warehouse_1] = BigDecimal.new stock
    stock = Material
      .select{sum(:b_qty).as(stock_warehouse_2)}
      .left_join(:bulks, materials__m_id: :bulks__m_id, b_loc: Location::W2)
      .where(materials__m_id: @values[:m_id])
      .first[:stock_warehouse_2]
    stock ||= 0
    @values[:stock_warehouse_2] = BigDecimal.new stock
  end

  def create_default
    last_m_id = "ERROR"
    DB.transaction do
      material = Material.new
      material.save validate: false
      last_m_id = DB.fetch( "SELECT last_insert_id() AS m_id" ).first[:m_id]
      current_user_id =  User.new.current_user_id
      current_location = User.new.current_location[:name]
      message = R18n.t.material.created
      ActionsLog.new.set(msg: message, u_id: current_user_id, l_id: current_location, lvl: ActionsLog::INFO, m_id: last_m_id).save
    end
    last_m_id
  end


  def validate
    super
    errors.add(:Nombre, R18n.t.errors.presence) if !m_name || m_name.empty?
    errors.add(:m_id, R18n.t.errors.numeric_feedback(m_id, m_id.class) ) unless m_id.class == Fixnum
    errors.add(:m_id, R18n.t.errors.positive_feedback(m_id) ) unless m_id.class == Fixnum && m_id > 0
  end


  def get_list warehouse_name
    begin
      base_query(warehouse_name)
        .order(:c_name, :m_name)
    rescue Exception => @e
      p @e
      return []
    end
  end

  def get_by_id id, warehouse_name
    begin
      material = base_query(warehouse_name)
        .where(materials__m_id: id.to_i)
        .first
      material.location= @location unless material.nil?
      material
    rescue Exception => @e
      p @e
      return []
    end
  end

  private
    def base_query warehouse_name
      valid = [Bulk::NEW, Bulk::IN_USE, Bulk::VOID]
      Material.select_group(*Material::COLUMNS , :c_name)
        .left_join(:bulks___b1, b1__m_id: :materials__m_id, b1__b_status: valid, b1__b_loc: warehouse_name)
        .join(:materials_categories, [:c_id])
        .select_append{sum(:b1__b_qty).as(m_qty)}
    end

end

