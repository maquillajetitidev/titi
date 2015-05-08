# coding: UTF-8
require 'sequel'
require 'json'
require_relative 'item'

class Category < Sequel::Model
  one_to_many :products

  ATTRIBUTES = [:c_id, :c_name, :description, :c_published, :img]
  # same as ATTRIBUTES but with the neccesary table references for get_ functions
  COLUMNS = [:categories__c_id, :categories__c_name, :categories__description, :c_published, :categories__img]

  def update_from_hash hash_values
    raise ArgumentError, t.errors.nil_params if hash_values.nil?
    alpha_keys = [ :c_name, :description ]
    hash_values.select { |key, value| self[key.to_sym]=value.to_s if alpha_keys.include? key.to_sym unless value.nil?}
    checkbox_keys = [ :c_published ]
    checkbox_keys.each { |key| self[key.to_sym] = hash_values[key].nil? ? 0 : 1 }
    self
  end

  def empty?
    return !!!@values[:c_id]
  end

  def get_by_id c_id
     c_id = c_id.to_i
     category = Category[c_id]
     category = Category.new if category.nil?
     category
  end

end


class Product < Sequel::Model

  STORE_ONLY_1 = "STORE_ONLY_1"
  STORE_ONLY_2 = "STORE_ONLY_2"
  STORE_ONLY_3 = "STORE_ONLY_3"
  ALL_LOCATIONS_1 = "ALL_LOCATIONS_1"
  ALL_LOCATIONS_2 = "ALL_LOCATIONS_2"
  ALL_LOCATIONS_3 = "ALL_LOCATIONS_3"
  DEVIATION_CALCULATION_MODES = [STORE_ONLY_1, STORE_ONLY_2, STORE_ONLY_3, ALL_LOCATIONS_1, ALL_LOCATIONS_2, ALL_LOCATIONS_3]

  @inventory = nil

  require_relative 'product_sql.rb'
  require_relative 'product_perms.rb'

  def inventory for_months = 1
    return @inventory unless @inventory.nil? or @inventory_months != for_months
    @inventory = OpenStruct.new
    @inventory_months = for_months
    store_1 = OpenStruct.new
    # store_1.stock = supply.s1
    # store_1.en_route = supply.s1_en_route
    # store_1.virtual =  supply.s1_future
    # store_1.ideal = supply.s1_ideal * for_months # HERE !!!
    # store_1.deviation = supply.s1 - store_1.ideal
    # store_1.deviation_percentile = supply.s1_deviation * 100 / store_1.ideal
    #                                store_1.deviation_percentile = BigDecimal.new(0, 2) if store_1.deviation_percentile.nan? or store_1.deviation_percentile.infinite? or store_1.deviation_percentile.nil?
    # store_1.v_deviation = supply.s1_future - store_1.ideal
    # store_1.v_deviation_percentile = store_1.v_deviation * 100 / store_1.ideal
    #                                  store_1.v_deviation_percentile = BigDecimal.new(0, 2) if store_1.v_deviation_percentile.nan? or store_1.v_deviation_percentile.infinite? or store_1.v_deviation_percentile.nil?

    # warehouse_1 = OpenStruct.new
    # warehouse_1.stock = supply.w1
    # warehouse_1.en_route = supply.w1_whole_en_route
    # warehouse_1.virtual = supply.w1_whole_future

    # warehouse_2 = OpenStruct.new
    # warehouse_2.stock = supply.w2_whole
    # warehouse_2.en_route = supply.w2_whole_en_route
    # warehouse_2.virtual = supply.w2_whole_future

    # warehouses = OpenStruct.new
    # warehouses.stock = supply.warehouses
    # warehouses.virtual =  supply.warehouses_future
    # warehouses.ideal = supply.warehouses_ideal * for_months # HERE !!!
    # warehouses.deviation = supply.warehouses - warehouses.ideal

    # warehouses.deviation_percentile = warehouses.deviation * 100 / warehouses.ideal
    # warehouses.deviation_percentile = BigDecimal.new(0, 2) if warehouses.deviation_percentile.nan? or warehouses.deviation_percentile.infinite? or warehouses.deviation_percentile.nil?
    # warehouses.v_deviation = supply.warehouses_whole_future - warehouses.ideal
    # warehouses.v_deviation_percentile = warehouses.v_deviation * 100 / warehouses.ideal
    # warehouses.v_deviation_percentile = BigDecimal.new(0, 2) if warehouses.v_deviation_percentile.nan? or warehouses.v_deviation_percentile.infinite? or warehouses.v_deviation_percentile.nil?

    global = OpenStruct.new
    # global.stock = supply.global_whole
    # global.en_route = supply.global_whole_en_route
    # global.virtual = supply.global_whole_future
    global.ideal = supply.global_ideal * for_months
    # global.in_assemblies = supply.global_part

    # global.deviation = supply.global - global.ideal
    # global.deviation_percentile = global.deviation * 100 / global.ideal
    # global.deviation_percentile = BigDecimal.new(0, 2) if global.deviation_percentile.nan? or global.deviation_percentile.infinite? or global.deviation_percentile.nil?
    global.v_deviation = supply.global_future - global.ideal
    global.v_deviation_percentile = global.v_deviation * 100 / global.ideal
                                    global.v_deviation_percentile = BigDecimal.new(0, 2) if global.v_deviation_percentile.nan? or global.v_deviation_percentile.infinite? or global.v_deviation_percentile.nil?



    @inventory.store_1 = store_1
    @inventory.global = global
    @inventory
  end

  def recalculate_markups
    self[:real_markup] = self[:price] / self[:sale_cost] if self[:sale_cost] > 0
    self[:ideal_markup] = self[:real_markup] if self[:ideal_markup] == 0 and self[:real_markup] > 0
    self[:price_pro] = BigDecimal.new(self[:price], 2) * 0.9
    self
  end

  def recalculate_sale_cost
    self[:sale_cost] = BigDecimal.new(self[:buy_cost] + self[:parts_cost] + self[:materials_cost], 2)
    recalculate_markups
  end

  def materials_cost= cost
    self[:materials_cost] = cost
    recalculate_sale_cost
    super cost
  end

  def parts_cost= cost
    self[:parts_cost] = cost
    recalculate_sale_cost
    super cost
  end

  def buy_cost= cost
    self[:buy_cost] = cost
    recalculate_sale_cost
    super cost
  end

  def sale_cost
    BigDecimal.new(self[:buy_cost] + self[:parts_cost] + self[:materials_cost], 2)
  end

  def buy_cost_mod mod
    mod = BigDecimal.new(mod.to_s.gsub(',', '.'), 15)
    if mod > 0
      self[:old_buy_cost] = self.buy_cost.dup
      self.buy_cost *= mod
      self[:new_buy_cost] = self.buy_cost
      recalculate_markups
    end
    self
  end

  def price_mod mod
    mod = BigDecimal.new(mod.to_s.gsub(',', '.'), 15)
    if mod > 0
      self[:old_price] = self.price.dup
      self.exact_price *= mod
      self.price = self.exact_price
      self[:new_price] = self.price
      recalculate_markups
    end
    self
  end

  def name
    self.p_name
  end

  def perform
    # TODO: raise errors as warning message
    begin
      message = "Recalculando producto #{self.p_id}: #{self.p_name}"
      self.update_costs
      self.recalculate_markups
      self.update_stocks
      self.update_ideal_stock
      self.save validate: false
      ActionsLog.new.set(msg: message, u_id: 1, l_id: Location::GLOBAL, lvl: ActionsLog::INFO, p_id: self.p_id).save
      self.validate
      if self.errors.count > 0
        message = "Error recalculando producto #{self.p_id} #{self.p_name}: #{self.errors.to_a.flatten.join(" ")}"
        ActionsLog.new.set(msg: message[0..254], u_id: 1, l_id: Location::GLOBAL, lvl: ActionsLog::ERROR, p_id: self.p_id).save
      end
    rescue => detail
      message = "Error critico: #{detail.message} #{$@}"
      ActionsLog.new.set(msg: message[0..254], u_id: 1, l_id: Location::GLOBAL, lvl: ActionsLog::ERROR).save
    end
  end

  def hash
    p_id.hash
  end
  def eql? product
    self.p_id == product.p_id
  end

  def name
    self.p_name
  end

  def price= price
    price = price > 100 ? price.round : price.round(1)
    self[:price] = BigDecimal.new(price, 1)
    recalculate_markups
  end

  def price
    self[:price]
  end

  def sku= sku
    sku = sku.to_s.gsub(/\n|\r|\t/, '').squeeze(" ").strip
    @values[:sku] = sku.empty? ? nil : sku
    self
  end

  def empty?
    return @values[:p_id].nil? ? true : false
  end

  def set_life_phase life_phase
    return self if life_phase.nil?
    case life_phase.to_sym
      when :active
        self.end_of_life = false
        self.archived = false
      when :end_of_life
        self.end_of_life = true
        self.archived = false
      when :archived
        archive
    end
    self
  end

  def life_phase
    return :archived if self.archived
    return :end_of_life if self.end_of_life
    return :active
  end

  def on_request= truth
    self.supply.s1_whole_ideal = 0 if truth
    super truth
  end

  def set_sale_mode sale_mode
    return self if sale_mode.nil?
    case sale_mode.to_sym
      when :normal
        self.on_request = false
        self.non_saleable = false
      when :on_request
        self.on_request = true
        self.non_saleable = false
      when :non_saleable
        self.on_request = false
        self.non_saleable = true
    end
    self
  end

  def sale_mode
    return :non_saleable if self.non_saleable
    return :on_request if self.on_request
    return :normal
  end

  def status
    status = R18n.t.product.fields.life_cycle.active.to_s
    status = R18n.t.product.fields.sale_mode.on_request.to_s if self.on_request
    status = R18n.t.product.fields.sale_mode.non_saleable.to_s if self.non_saleable
    status = R18n.t.product.fields.life_cycle.end_of_life.to_s if self.end_of_life
    status = R18n.t.product.fields.life_cycle.archived.to_s if self.archived
    status
  end


  def validate
    super
    validates_schema_types [:p_id, :p_id]
    validates_schema_types [:c_id, :c_id]
    validates_schema_types [:p_name, :p_name]
    validates_schema_types [:p_short_name, :p_short_name]
    validates_schema_types [:br_name, :br_name]
    validates_schema_types [:br_id, :br_id]
    validates_schema_types [:packaging, :packaging]
    validates_schema_types [:size, :size]
    validates_schema_types [:color, :color]
    validates_schema_types [:sku, :sku]
    validates_schema_types [:public_sku, :public_sku]
    validates_schema_types [:buy_cost, :buy_cost]
    validates_schema_types [:sale_cost, :sale_cost]
    validates_schema_types [:ideal_markup, :ideal_markup]
    validates_schema_types [:real_markup, :real_markup]
    validates_schema_types [:exact_price, :exact_price]
    validates_schema_types [:price, :price]
    validates_schema_types [:price_pro, :price_pro]
    validates_schema_types [:published_price, :published_price]
    validates_schema_types [:published, :published]
    validates_schema_types [:archived, :archived]
    validates_schema_types [:description, :description]
    validates_schema_types [:notes, :notes]
    validates_schema_types [:img, :img]
    validates_schema_types [:img_extra, :img_extra]

    validates_presence [:p_name, :p_short_name, :stock_store_1, :stock_store_2, :stock_warehouse_1, :stock_warehouse_2, :exact_price, :price]

    errors.add("La marca", "No puede estar vacia" ) if self[:br_id].nil?
    # errors.add("El costo de venta", "no puede ser cero" ) if self[:sale_cost] == 0
    errors.add("El markup ideal", "no puede ser cero" ) if self[:ideal_markup] == 0
    errors.add("El markup real", "no puede ser cero." ) if self[:real_markup] == 0
    # errors.add("El precio exacto", "no puede ser cero" ) if self[:exact_price] == 0
    errors.add("El precio", "no puede ser cero" ) if self.price == 0
    errors
  end

  def update_from_hash(hash_values)
    raise ArgumentError, t.errors.nil_params if hash_values.nil?
    hash_values.select do |key, value|
      if Product::NUMERICAL_ATTRIBUTES.include? key.to_sym
        unless value.nil? or (value.class == String and value.length == 0)
          modified_value = value.to_s.gsub(',', '.')
          if Utils::is_numeric? modified_value
            self[key.to_sym] = BigDecimal.new(modified_value, 2)
          end
        end
      end
    end

    alpha_keys = [ :c_id, :p_short_name, :packaging, :size, :color, :sku, :public_sku, :description, :notes, :img, :img_extra ]
    hash_values.select { |key, value| eval("self.#{key}=value.to_s") if alpha_keys.include? key.to_sym unless value.nil?}

    checkbox_keys = [:published_price, :published]
    checkbox_keys.each { |key| self[key.to_sym] = hash_values[key].nil? ? 0 : 1 }

    true_false_keys = [:tercerized]
    true_false_keys.each { |key| self[key.to_sym] = hash_values[key] == "true" ? 1 : 0 }

    set_life_phase hash_values[:life_phase]
    set_sale_mode hash_values[:sale_mode]

    unless hash_values[:brand].nil?
      brand_json = JSON.parse(hash_values[:brand])
      brand_keys = [ :br_id, :br_name ]
      brand_keys.select { |key, value| self[key.to_sym]=brand_json[key.to_s] unless brand_json[key.to_s].nil?}
    end

    self[:p_name] = ""
    [self[:p_short_name], self[:br_name], self[:packaging], self[:size], self[:color], self[:public_sku] ].map  { |part| self[:p_name] += " " + part unless part.nil?}
    @values[:ideal_stock] = @values[:direct_ideal_stock] + @values[:indirect_ideal_stock]

    recalculate_markups

    self
  end

  private

    def cast
      Product::NUMERICAL_ATTRIBUTES.each { |key| self[key] = BigDecimal.new(0, 2) if self[key].nil?}
    end

    def must_be_archived?
      self.end_of_life and supply.global == 0
    end

    def must_be_revived?
      self.archived and supply.global > 0
    end

    def archive_or_revive
      return archive if must_be_archived?
      return revive if must_be_revived?
      self
    end

    def archive
      current_user_id =  User.new.current_user_id
      current_location = User.new.current_location[:name]
      if supply.global == 0
        self.end_of_life = false
        self.archived =  true
        message = "Archivado por agotar existencias"
        ActionsLog.new.set(msg: message, u_id: current_user_id, l_id: current_location, lvl: ActionsLog::NOTICE, p_id: self.p_id).save
        save
      else
        self.end_of_life = true
        self.archived = false
        save
        message = 'No se puede archivar un producto hasta que su stock sea 0. Seteado a "Fin de vida"'
        errors.add "Error de ingreso", message
        ActionsLog.new.set(msg: message, u_id: current_user_id, l_id: current_location, lvl: ActionsLog::WARN, p_id: self.p_id).save
      end
      self
    end

    def revive
      if supply.global > 0
        self.end_of_life = true
        self.archived =  false
        current_user_id =  User.new.current_user_id
        current_location = User.new.current_location[:name]
        message = 'Producto seteado en estado "Fin de vida" por tener stock'
        ActionsLog.new.set(msg: message, u_id: current_user_id, l_id: current_location, lvl: ActionsLog::WARN, p_id: self.p_id).save
        save
      end
      self
    end

end
