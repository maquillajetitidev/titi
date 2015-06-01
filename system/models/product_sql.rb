# coding: UTF-8

class Supply < Sequel::Model
  one_to_one :product, key: :p_id
  META_ATTRIBUTES = [:p_id, :updated_at]
  NUMERIC_ATTRIBUTES = [:s1_whole, :s1_whole_en_route, :s1_whole_future, :s1_whole_ideal, :s1_whole_deviation, :s1_part, :s1_part_en_route, :s1_part_future, :s1_part_ideal, :s1_part_deviation, :s1, :s1_en_route, :s1_future, :s1_ideal, :s1_deviation, :s2_whole, :s2_whole_en_route, :s2_whole_future, :s2_whole_ideal, :s2_whole_deviation, :s2_part, :s2_part_en_route, :s2_part_future, :s2_part_ideal, :s2_part_deviation, :s2, :s2_en_route, :s2_future, :s2_ideal, :s2_deviation, :stores_whole, :stores_whole_en_route, :stores_whole_future, :stores_whole_ideal, :stores_whole_deviation, :stores_part, :stores_part_en_route, :stores_part_future, :stores_part_ideal, :stores_part_deviation, :stores, :stores_en_route, :stores_future, :stores_ideal, :stores_deviation, :w1_whole, :w1_whole_en_route, :w1_whole_future, :w1_whole_ideal, :w1_whole_deviation, :w1_part, :w1_part_en_route, :w1_part_future, :w1_part_ideal, :w1_part_deviation, :w1, :w1_en_route, :w1_future, :w1_ideal, :w1_deviation, :w2_whole, :w2_whole_en_route, :w2_whole_future, :w2_whole_ideal, :w2_whole_deviation, :w2_part, :w2_part_en_route, :w2_part_future, :w2_part_ideal, :w2_part_deviation, :w2, :w2_en_route, :w2_future, :w2_ideal, :w2_deviation, :warehouses_whole, :warehouses_whole_en_route, :warehouses_whole_future, :warehouses_whole_ideal, :warehouses_whole_deviation, :warehouses_part, :warehouses_part_en_route, :warehouses_part_future, :warehouses_part_ideal, :warehouses_part_deviation, :warehouses, :warehouses_en_route, :warehouses_future, :warehouses_ideal, :warehouses_deviation, :global_whole, :global_whole_en_route, :global_whole_future, :global_whole_ideal, :global_whole_deviation, :global_part, :global_part_en_route, :global_part_future, :global_part_ideal, :global_part_deviation, :global, :global_en_route, :global_future, :global_ideal, :global_deviation]
  ATTRIBUTES = META_ATTRIBUTES + NUMERIC_ATTRIBUTES
  COLUMNS = [:supplies__p_id, :supplies__updated_at] + NUMERIC_ATTRIBUTES


  # TODO: delete these columns
  PRODUCT_EQ = {
    direct_ideal_stock: :s1_whole_ideal,
    indirect_ideal_stock: :stores_part,
    ideal_stock: :stores_ideal,
    stock_deviation: :global_deviation,
    stock_store_1: :s1_whole,
    stock_store_2: :w2_whole,
    stock_warehouse_1: :w1_whole,
    stock_warehouse_2: :w2_whole
  }

  @supply = nil

  def get p_id
    return @supply unless @supply.nil?
    @supply = Supply.select_group(*Supply::COLUMNS).filter(p_id: p_id.to_i).first
    product = Product.new.get p_id
    @supply = init(product) if @supply.nil?
    @supply
  end

  def init product = Product.new
    Sequel::Plugins::DefaultsSetter.configure(self.class)
    Supply.default_values.each { |key, val| self.send("#{key}=", val) } # default setter
    self
    @supply = self
    self
  end

  def empty?
    return !!!self.p_id
  end

  def s1_whole_ideal= ideal # business logic
    ideal = typecast_value(:s1_whole_ideal, ideal)
    @values[:s1_whole_ideal] = ideal
    @values[:w1_whole_ideal] = ideal
    super ideal
    recalculate_ideals
  end
  def w1_whole_ideal= ideal # business logic
    @values[:s1_whole_ideal] = ideal
    @values[:w1_whole_ideal] = ideal
    s1_whole_ideal= ideal
    super ideal
    recalculate_ideals
  end

  def s1_part_ideal= ideal # business logic
    ideal = typecast_value(:s1_part_ideal, ideal)
    @values[:s1_part_ideal] = ideal
    @values[:w1_part_ideal] = ideal
    super ideal
    recalculate_ideals
  end
  def w1_part_ideal= ideal # business logic
    @values[:s1_part_ideal] = ideal
    @values[:w1_part_ideal] = ideal
    s1_part_ideal= ideal
    super ideal
    recalculate_ideals
  end



  def recalculate_ideals
    # ap self
    "s1_whole_ideal" # temporal
    self.s1_whole_deviation = self.s1_whole - self.s1_whole_ideal
    "s1_part_ideal" # temporal
    self.s1_part_deviation = self.s1_part - self.s1_part_ideal
    self.s1_ideal = self.s1_whole_ideal + self.s1_part_ideal
    self.s1_deviation = self.s1_part_deviation < 0 && self.s1_whole_deviation < 0 ? self.s1_part_deviation + self.s1_whole_deviation : [self.s1_part_deviation, self.s1_whole_deviation].min


    self.s2_whole_ideal = 0
    self.s2_whole_deviation = 0
    self.s2_part_ideal = 0
    self.s2_part_deviation = 0
    self.s2_ideal = 0
    self.s2_deviation = 0

    self.stores_whole_ideal = self.s1_whole_ideal + self.s2_whole_ideal
    self.stores_whole_deviation = self.stores_whole - self.stores_whole_ideal
    self.stores_part_ideal = self.s1_part_ideal + self.s2_part_ideal
    self.stores_part_deviation = self.stores_part - self.stores_part_ideal
    self.stores_ideal = self.s1_ideal + self.s2_ideal
    self.stores_deviation = self.stores - self.stores_ideal

    "w1_whole_ideal"
    self.w1_whole_deviation = self.w1_whole - self.w1_whole_ideal
    "w1_part_ideal"
    self.w1_part_deviation = self.w1_part - self.w1_part_ideal
    self.w1_ideal = self.w1_whole_ideal + self.w1_part_ideal
    self.w1_deviation = self.w1_part_deviation < 0 && self.w1_whole_deviation < 0 ? self.w1_part_deviation + self.w1_whole_deviation : [self.w1_part_deviation, self.w1_whole_deviation].min

    self.w2_whole_ideal = 0
    self.w2_whole_deviation = self.w2_whole - self.w2_whole_ideal
    self.w2_part_ideal = 0
    self.w2_part_deviation = self.w2_part - self.w2_part_ideal
    self.w2_ideal = self.w2_whole_ideal + self.w2_part_ideal
    self.w2_deviation = self.w2 - self.w2_ideal

    self.warehouses_whole_ideal = self.w1_whole_ideal + self.w2_whole_ideal
    self.warehouses_whole_deviation = self.warehouses_whole - self.warehouses_whole_ideal
    self.warehouses_part_ideal = self.w1_part_ideal + self.w2_part_ideal
    self.warehouses_part_deviation = self.warehouses_part - self.warehouses_part_ideal
    self.warehouses_ideal = self.w1_ideal + self.w2_ideal
    self.warehouses_deviation = self.warehouses - self.warehouses_ideal

    self.global_whole_ideal = self.stores_whole_ideal + self.warehouses_whole_ideal
    self.global_whole_deviation = self.global_whole - self.global_whole_ideal
    self.global_part_ideal = self.stores_part_ideal + self.warehouses_part_ideal
    self.global_part_deviation = self.global_part - self.global_part_ideal
    self.global_ideal = self.stores_ideal + self.warehouses_ideal
    self.global_deviation = self.global_part_deviation < 0 && self.global_whole_deviation < 0 ? self.global_part_deviation + self.global_whole_deviation : [self.global_part_deviation, self.global_whole_deviation].min
  end

end


















class Product < Sequel::Model
  one_to_one :supply, key: :p_id
  many_to_one :category, key: :c_id
  one_to_many :items, key: :p_id
  Product.nested_attributes :items
  many_to_many :materials , left_key: :product_id, right_key: :m_id, join_table: :products_materials
  many_to_many :products_parts , left_key: :p_id, right_key: :p_id, join_table: :products_parts
  many_to_many :distributors , left_key: :p_id, right_key: :d_id, join_table: :products_to_distributors


  NUMERICAL_ATTRIBUTES = [ :direct_ideal_stock, :indirect_ideal_stock, :stock_store_1, :stock_store_2, :stock_warehouse_1, :stock_warehouse_2, :stock_deviation, :buy_cost, :materials_cost, :parts_cost, :sale_cost, :ideal_markup, :real_markup, :exact_price, :price, :price_pro]
  ATTRIBUTES = [:p_id, :c_id, :p_name, :p_short_name, :br_name, :br_id, :packaging, :size, :color, :sku, :public_sku, :direct_ideal_stock, :indirect_ideal_stock, :ideal_stock, :on_request, :non_saleable, :stock_deviation, :stock_warehouse_1, :stock_warehouse_2, :stock_store_1, :stock_store_2, :buy_cost, :parts_cost, :materials_cost, :sale_cost, :ideal_markup, :real_markup, :exact_price, :price, :price_pro, :published_price, :published, :archived, :tercerized, :end_of_life, :description, :notes, :img, :img_extra, :created_at, :price_updated_at]
  # same as ATTRIBUTES but with the neccesary table references for get_ functions
  COLUMNS = [:products__p_id, :c_id, :p_name, :p_short_name, :br_id, :packaging, :size, :color, :sku, :public_sku, :notes, :direct_ideal_stock, :indirect_ideal_stock, :ideal_stock, :stock_deviation, :stock_warehouse_1, :stock_warehouse_2, :stock_store_1, :stock_store_2, :buy_cost, :parts_cost, :materials_cost, :sale_cost, :ideal_markup, :real_markup, :exact_price, :price, :price_pro, :published_price, :tercerized, :published, :on_request, :non_saleable, :archived, :end_of_life, :products__img, :img_extra, :products__created_at, :products__price_updated_at, :products__description, :brands__br_name]
  EXCLUDED_ATTRIBUTES_IN_DUPLICATION = [:p_id, :end_of_life, :archived, :published, :img, :img_extra, :sku, :public_sku, :stock_warehouse_1, :stock_warehouse_2, :stock_store_1, :stock_store_2, :stock_deviation, :created_at, :price_updated_at]

  @supply = nil
  @distributors = nil

  def supply
    return @supply unless @supply.nil?
    @supply = Supply.new.get p_id
    @supply
  end

  def init product = Product.new
    Product.default_values.each { |key, val| self.send("#{key}=", val) } # default setter
    self
  end



  def update_ideal_stock debug = false

    # temporal
    ap "update_ideal_stock (#{p_id})" if debug
    p "direct_ideal_stock: #{direct_ideal_stock.to_s("F")} (x2)" if debug
    indirect_ideal_stock = BigDecimal.new(0)
    p "indirect_ideal_stock: #{indirect_ideal_stock.to_s("F")}" if debug
    assemblies.each do |assembly|
      p "adding #{assembly.p_name} #{(assembly[:part_qty] * assembly.supply.s1_ideal unless assembly.archived).to_s("F")}" if debug
      indirect_ideal_stock += assembly[:part_qty] * assembly.supply.s1_ideal unless assembly.archived
      p "indirect_ideal_stock: #{indirect_ideal_stock.to_s("F")}" if debug
    end

    supply.s1_whole_ideal = direct_ideal_stock # temporal
    supply.s1_part_ideal = indirect_ideal_stock # temporal
    supply.w1_whole_ideal = direct_ideal_stock # temporal
    supply.w1_part_ideal = indirect_ideal_stock # temporal

    supply.recalculate_ideals

    self
  end



  def update_stocks
    "p_id"

    supply.s1_whole = BigDecimal.new Product.select{count(i_id).as(stock_store_1)}.left_join(:items, products__p_id: :items__p_id, i_status: Item::READY, i_loc: Location::S1).where(products__p_id: @values[:p_id]).first[:stock_store_1]
    self.stock_store_1 = supply.s1_whole
    supply.s1_whole_en_route = BigDecimal.new Product.select{count(i_id).as(s1_whole_en_route)}.left_join(:items, products__p_id: :items__p_id, i_status: Item::MUST_VERIFY, i_loc: Location::S1).where(products__p_id: @values[:p_id]).first[:s1_whole_en_route]
    supply.s1_whole_future = supply.s1_whole + supply.s1_whole_en_route
    "s1_whole_ideal"
    "s1_whole_deviation"
    supply.s1_part = PartsToAssemblies.get_items_via_assembly_part_p_id_and_location(self.p_id, Location::S1).all.count
    supply.s1_part_en_route = PartsToAssemblies.get_items_via_assembly_part_p_id_en_route_to_location(self.p_id, Location::S1).all.count
    supply.s1_part_future = supply.s1_part + supply.s1_part_en_route
    "s1_part_ideal"
    "s1_part_deviation"
    supply.s1 = supply.s1_part + supply.s1_whole
    supply.s1_en_route = supply.s1_part_en_route + supply.s1_whole_en_route
    supply.s1_future = supply.s1 + supply.s1_en_route
    "s1_ideal"
    "s1_deviation"

    supply.s2_whole = BigDecimal.new Product.select{count(i_id).as(stock_store_2)}.left_join(:items, products__p_id: :items__p_id, i_status: Item::READY, i_loc: Location::S2).where(products__p_id: @values[:p_id]).first[:stock_store_2]
      self.stock_store_2 = supply.s2_whole
    supply.s2_whole_en_route = BigDecimal.new Product.select{count(i_id).as(s2_whole_en_route)}.left_join(:items, products__p_id: :items__p_id, i_status: Item::MUST_VERIFY, i_loc: Location::S2).where(products__p_id: @values[:p_id]).first[:s2_whole_en_route]
    supply.s2_whole_future = supply.s2_whole + supply.s2_whole_en_route
    "s2_whole_ideal"
    "s2_whole_deviation"
    supply.s2_part = PartsToAssemblies.get_items_via_assembly_part_p_id_and_location(self.p_id, Location::S2).all.count
    supply.s2_part_en_route = PartsToAssemblies.get_items_via_assembly_part_p_id_en_route_to_location(self.p_id, Location::S2).all.count
    supply.s2_part_future = supply.s2_part + supply.s2_part_en_route
    "s2_part_ideal"
    "s2_part_deviation"
    supply.s2 = supply.s2_part + supply.s2_whole
    supply.s2_en_route = supply.s2_part_en_route + supply.s2_whole_en_route
    supply.s2_future = supply.s2 + supply.s2_en_route
    "s2_ideal"
    "s2_deviation"

    supply.stores_whole = supply.s1_whole + supply.s2_whole
    supply.stores_whole_en_route = supply.s1_whole_en_route + supply.s2_whole_en_route
    supply.stores_whole_future = supply.s1_whole_future + supply.s2_whole_future
    "stores_whole_ideal"
    "stores_whole_deviation"
    supply.stores_part = supply.s1_part + supply.s2_part
    supply.stores_part_en_route = supply.s1_part_en_route + supply.s2_part_en_route
    supply.stores_part_future = supply.s1_part_future + supply.s2_part_future
    "stores_part_ideal"
    "stores_part_deviation"
    supply.stores = supply.s1 + supply.s2
    supply.stores_en_route = supply.stores_whole_en_route + supply.stores_part_en_route
    supply.stores_future = supply.s1_future + supply.s2_future
    "stores_ideal"
    "stores_deviation"

    supply.w1_whole = BigDecimal.new Product.select{count(i_id).as(stock_warehouse_1)}.left_join(:items, products__p_id: :items__p_id, i_status: Item::READY, i_loc: Location::W1).where(products__p_id: @values[:p_id]).first[:stock_warehouse_1]
      self.stock_warehouse_1 = supply.w1_whole
    supply.w1_whole_en_route = BigDecimal.new Product.select{count(i_id).as(w1_whole_en_route)}.left_join(:items, products__p_id: :items__p_id, i_status: Item::MUST_VERIFY, i_loc: Location::W1).where(products__p_id: @values[:p_id]).first[:w1_whole_en_route]
    supply.w1_whole_future = supply.w1_whole + supply.w1_whole_en_route
    "w1_whole_ideal"
    "w1_whole_deviation"
    supply.w1_part = PartsToAssemblies.get_items_via_assembly_part_p_id_and_location(self.p_id, Location::W1).all.count
    supply.w1_part_en_route = PartsToAssemblies.get_items_via_assembly_part_p_id_en_route_to_location(self.p_id, Location::W1).all.count
    supply.w1_part_future = supply.w1_part + supply.w1_part_en_route
    "w1_part_ideal"
    "w1_part_deviation"
    supply.w1 = supply.w1_part_future + supply.w1_whole_future
    supply.w1_en_route = supply.w1_part_en_route + supply.w1_whole_en_route
    supply.w1_future = supply.w1_en_route + supply.w1
    "w1_ideal"
    "w1_deviation"

    supply.w2_whole = BigDecimal.new Product.select{count(i_id).as(stock_warehouse_2)}.left_join(:items, products__p_id: :items__p_id, i_status: Item::READY, i_loc: Location::W2).where(products__p_id: @values[:p_id]).first[:stock_warehouse_2]
      self.stock_warehouse_2 = supply.w2_whole
    supply.w2_whole_en_route = BigDecimal.new Product.select{count(i_id).as(w2_whole_en_route)}.left_join(:items, products__p_id: :items__p_id, i_status: Item::MUST_VERIFY, i_loc: Location::W2).where(products__p_id: @values[:p_id]).first[:w2_whole_en_route]
    supply.w2_whole_future = supply.w2_whole + supply.w2_whole_en_route
    "w2_whole_ideal"
    "w2_whole_deviation"
    supply.w2_part = PartsToAssemblies.get_items_via_assembly_part_p_id_and_location(self.p_id, Location::W2).all.count
    supply.w2_part_en_route = PartsToAssemblies.get_items_via_assembly_part_p_id_en_route_to_location(self.p_id, Location::W2).all.count
    supply.w2_part_future = supply.w2_part + supply.w2_part_en_route
    "w2_part_ideal"
    "w2_part_deviation"
    supply.w2 = supply.w2_part_future + supply.w2_whole_future
    supply.w2_en_route = supply.w2_part_en_route + supply.w2_whole_en_route
    supply.w2_future = supply.w2_en_route + supply.w2
    "w2_ideal"
    "w2_deviation"

    supply.warehouses_whole = supply.w1_whole + supply.w2_whole
    supply.warehouses_whole_en_route = supply.w1_whole_en_route + supply.w2_whole_en_route
    supply.warehouses_whole_future = supply.warehouses_whole + supply.warehouses_whole_en_route
    "warehouses_whole_ideal"
    "warehouses_whole_deviation"
    supply.warehouses_part = supply.w1_part + supply.w2_part
    supply.warehouses_part_en_route = supply.w1_part_en_route + supply.w2_part_en_route
    supply.warehouses_part_future = supply.warehouses_part + supply.warehouses_part_en_route
    "warehouses_part_ideal"
    "warehouses_part_deviation"
    supply.warehouses = supply.w1 + supply.w2
    supply.warehouses_en_route = supply.w1_en_route + supply.w2_en_route
    supply.warehouses_future = supply.warehouses + supply.warehouses_en_route
    "warehouses_ideal"
    "warehouses_deviation"

    supply.global_whole = supply.stores_whole + supply.warehouses_whole
    supply.global_whole_en_route = supply.stores_whole_en_route + supply.warehouses_whole_en_route
    supply.global_whole_future = supply.global_whole + supply.global_whole_en_route
    "global_whole_ideal"
    "global_whole_deviation"
    supply.global_part = supply.stores_part + supply.warehouses_part
    supply.global_part_en_route = supply.stores_part_en_route + supply.warehouses_part_en_route
    supply.global_part_future = supply.global_part + supply.global_part_en_route
    "global_part_ideal"
    "global_part_deviation"
    supply.global = supply.stores + supply.warehouses
    supply.global_en_route = supply.stores_en_route + supply.warehouses_en_route
    supply.global_future = supply.global + supply.global_en_route
    supply.global_ideal = supply.stores_ideal + supply.warehouses_ideal
    "global_deviation"

    self
  end

  def update_costs
    parts_cost
    materials_cost
    self
  end
  def materials_cost
    cost = BigDecimal.new 0, 6
    self.materials.map { |material| cost +=  material[:m_qty] * material[:m_price] }
    p "el costo de materiales retorno nil" if cost.nil?
    self.materials_cost = cost.round(3)
    cost.round(3)
  end
  def parts_cost
    cost = BigDecimal.new 0, 2
    self.parts.map { |part| cost += part.sale_cost * part[:part_qty]}
    p "el costo de partes retorno nil" if cost.nil?
    cost = BigDecimal.new 0, 2 if cost.nil?
    self.parts_cost = cost
    cost
  end

  def save (opts=OPTS)
    opts = opts.merge({columns: Product::ATTRIBUTES})
    self.end_of_life = false if self.archived
    cast
    self.update_stocks
    self.update_ideal_stock
    self.update_costs
    self.recalculate_markups
    archive_or_revive

    begin
      super(opts)[:p_id]
      supply.p_id = self.p_id
      supply.save
      if self.p_name and not self.archived
        current_user_id =  User.new.current_user_id
        current_location = User.new.current_location[:name]
        message = "Actualizando todos los items de #{self.p_name}"
        ActionsLog.new.set(msg: message, u_id: current_user_id, l_id: "GLOBAL", lvl: ActionsLog::NOTICE, p_id: self.p_id).save
        DB.run "UPDATE items
        JOIN products using(p_id)
        SET items.i_price = products.price, items.i_price_pro = products.price_pro, items.p_name = products.p_name
        WHERE p_id = #{self.p_id} AND i_status IN ( 'ASSIGNED', 'MUST_VERIFY', 'VERIFIED', 'READY' )"
      end
    rescue Sequel::UniqueConstraintViolation => e
      errors.add "Error, valor duplicado", e.message
    end
    self
  end

  def distributors
    # TODO: cache this dataset
    return [] unless self.p_id.to_i > 0
    distributors = Distributor
                    .select_group(*Distributor::COLUMNS, *ProductDistributor::COLUMNS)
                    .join(:products_to_distributors, distributors__d_id: :products_to_distributors__d_id, products_to_distributors__p_id: self.p_id)
                    .order(:products_to_distributors__ptd_id)
    @distributors = distributors
  end

  def d_name
    return self[:distributors].first[:d_name] if self[:distributors] && self[:distributors].empty? == false
    return self[:distributor][:d_name] if self[:distributor] && self[:distributor].empty? == false
    return "no data"
  end

  def create_default
    last_p_id = "ERROR"
    previous = Product.where(p_short_name: "NEW").first
    return previous.p_id unless previous.nil?
    DB.transaction do
      product = Product.new
      product[:public_sku] = rand
      product[:sku] = product[:public_sku]
      if product.errors.count > 0
        raise product.errors.to_a.flatten.join(": ")
      end
      product.save validate: false
      last_p_id = DB.fetch( "SELECT last_insert_id() AS p_id" ).first[:p_id]
      current_user_id =  User.new.current_user_id
      current_location = User.new.current_location[:name]
      message = R18n.t.product.created
      ActionsLog.new.set(msg: message, u_id: current_user_id, l_id: current_location, lvl: ActionsLog::INFO, p_id: last_p_id).save
    end
    last_p_id
  end

  def duplicate debug = false
    dest_id = create_default
    dest = Product[dest_id]
    self.parts.map { |part| dest.add_part part }
    self.materials.map { |material| dest.add_material material }
    self.distributors.map { |distributor| dest.add_distributor distributor }
    dest.update_from self, debug
    dest.save
    dest
  end
  def update_from product, debug = false
    columns_to_copy = ATTRIBUTES - EXCLUDED_ATTRIBUTES_IN_DUPLICATION
    columns_to_copy.each do |col|
      p "copying #{col} => #{product[col]}" if debug
      self[col] = product[col]
      @values[col] = product[col]
    end
    self
  end

  def get p_id
    return Product.new unless p_id.to_i > 0
    product = Product.select_group(*Product::COLUMNS, :brands__br_name, :categories__c_name)
                .filter(products__p_id: p_id.to_i)
                .left_join(:categories, [:c_id])
                .left_join(:brands, [:br_id])
                .left_join(:supplies, [:p_id])
                .first
    return Product.new if product.nil?
    product.br_name = product[:br_name]
    product
  end


  def parts
    # https://github.com/jeremyevans/sequel/blob/master/doc/querying.rdoc#join-conditions
    return [] if self.empty?
    condition = "product_id = #{self[:p_id]}"
    Product
      .join( ProductsPart.where{condition}, part_id: :products__p_id)
      .join( Category, [:c_id])
      .order(:p_name)
      .all
  end

  def add_part part
    errors.add "Error de ingreso", "La cantidad de la parte a agregar no puede ser cero ni negativa" if part[:part_qty] <= 0
    return false if part[:part_qty] <= 0
    ProductsPart.unrestrict_primary_key
    ProductsPart.create(product_id: self[:p_id], part_id: part[:p_id], part_qty: part[:part_qty])
    save
  end

  def remove_products_part part
    remove_part part
  end

  def remove_part part
    ProductsPart.filter(product_id: self[:p_id], part_id: part[:p_id]).first.delete
    save
  end

  def update_part part
    if part[:part_qty] < 0
      errors.add "Error de ingreso", "La cantidad de la parte no puede ser negativa"
      return ProductsPart.filter(product_id: self[:p_id], part_id: part[:p_id]).first
    end
    if part[:part_qty] == 0
      remove_part part
      return true
    end
    prod_part =  ProductsPart.filter(product_id: self[:p_id], part_id: part[:p_id]).first
    prod_part[:part_qty] = part[:part_qty]
    prod_part.save
    save
  end


  def materials
    return [] if self.empty?
    condition = "product_id = #{self.p_id}"
    Material
    .join( ProductsMaterial.where{condition}, [:m_id])
    .join( MaterialCategory, [:c_id])
    .order(:m_name)
    .all
  end

  def add_material material
    errors.add "Error de ingreso", "La cantidad del material a agregar no puede ser cero ni negativa" if material[:m_qty] <= 0
    return false if material[:m_qty] <= 0
    ProductsMaterial.unrestrict_primary_key
    ProductsMaterial.create(product_id: self[:p_id], m_id: material[:m_id], m_qty: material[:m_qty])
    save
  end

  def update_material material
    if material[:m_qty] < 0
      errors.add "Error de ingreso", "La cantidad del material no puede ser negativa"
      return ProductsMaterial.filter(product_id: self[:p_id], m_id: material[:m_id]).first
    end
    if material[:m_qty] == 0
      remove_material material
      save
      return true
    end
    prod_mat =  ProductsMaterial.filter(product_id: self[:p_id], m_id: material[:m_id]).first
    prod_mat[:m_qty] = material[:m_qty]
    prod_mat.save
    save
  end

  def assemblies
    product_part =  ProductsPart
                      .select{Sequel.lit('product_id').as(p_id)}
                      .select_append{:part_qty}
                      .where(part_id: self.p_id)
                      .all
    assemblies = []
    product_part.each do |assy|
      assembly = Product.new.get(assy[:p_id])
      assembly[:part_id] = self.p_id
      assembly[:part_qty] = assy[:part_qty]
      assembly[:part_cost] = self.sale_cost * assy[:part_qty]
      assemblies << assembly
    end
    assemblies
  end

  def items
    condition = "p_id = #{self[:p_id]}"
    Item.select(:i_id, :items__p_id, :items__p_name, :i_price, :i_price_pro, :i_status, :i_loc, :items__created_at).join( Product.where{condition}, [:p_id]).all
  end

  def add_item label, o_id
    o_id = o_id.to_i
    current_user_id =  User.new.current_user_id
    current_location = current_location
    if label.nil?
      message = R18n::t.errors.inexistent_label
      log = ActionsLog.new.set(msg: "#{message}", u_id: current_user_id, l_id: current_location, lvl:  ActionsLog::ERROR)
      log.set(o_id: o_id) unless o_id == 0
      log.save
      errors.add "General", message
      return ""
    end
    if label.class != Label
      message = R18n::t.errors.this_is_not_a_label(label.class)
      log = ActionsLog.new.set(msg: "#{message}", u_id: current_user_id, l_id: current_location, lvl:  ActionsLog::ERROR)
      log.set(o_id: o_id) unless o_id == 0
      log.save
      errors.add "General", message
      return ""
    end
    label.p_id = @values[:p_id]
    label.p_name = @values[:p_name]
    label.i_status = Item::ASSIGNED
    label.i_price = self.price
    label.i_price_pro = @values[:price_pro]
    begin
      label.save
      super label
      message = R18n::t.label.assigned(label.i_id, @values[:p_name])
      log = ActionsLog.new.set(msg: message, u_id: current_user_id, l_id: current_location, lvl:  ActionsLog::INFO, i_id: label.i_id, p_id: @values[:p_id])
      log.set(o_id: o_id) unless o_id == 0
      log.save
      return message
    rescue Sequel::ValidationFailed
      message = label.errors.to_s
      log = ActionsLog.new.set(msg: message, u_id: current_user_id, l_id: current_location, lvl:  ActionsLog::ERROR, i_id: label.i_id, p_id: @values[:p_id])
      log.set(o_id: o_id) unless o_id == 0
      log.save
      return message
    rescue => detail
      message = detail.message
      log = ActionsLog.new.set(msg: message, u_id: current_user_id, l_id: current_location, lvl:  ActionsLog::ERROR, i_id: label.i_id, p_id: @values[:p_id])
      log.set(o_id: o_id) unless o_id == 0
      log.save
      return message
    end
  end

  def remove_item item
    defaults = Item
                .select(:i_id)
                .select_append{default(:p_id).as(p_id)}
                .select_append{default(:p_name).as(p_name)}
                .select_append{default(:i_price).as(i_price)}
                .select_append{default(:i_price_pro).as(i_price_pro)}
                .select_append{default(:i_status).as(i_status)}
                .first
    item.p_id = defaults[:p_id]
    item.p_name = defaults[:p_name]
    item.i_price = defaults[:i_price]
    item.i_price_pro = defaults[:i_price_pro]
    item.i_status = Item::PRINTED
    item.save validate: false
    current_user_id =  User.new.current_user_id
    current_location = current_location
    message = R18n::t.product.item_removed
    ActionsLog.new.set(msg: message, u_id: current_user_id, l_id: current_location, lvl: ActionsLog::INFO, i_id: item.i_id, p_id: @values[:p_id]).save
  end

  def get_by_sku sku
    sku.to_s.gsub(/\n|\r|\t/, '').squeeze(" ").strip
    product = Product.filter(sku: sku).first
    product ||= Product.new
    product
  end

  def get_all
    Product
      .select_group(*Product::COLUMNS, :categories__c_name)
      .join(:categories, [:c_id])
      .join(:brands, [:br_id])
      .select_append{ Sequel.case( {{Sequel.lit('real_markup / ideal_markup') => nil} => 0}, Sequel.lit('(real_markup * 100 / ideal_markup) - 100') ).as(markup_deviation_percentile)}
      .order(:c_name, :p_name)
  end

  def get_all_but_archived
    get_all
      .where(archived: 0)
  end

  def get_live
    get_all_but_archived
      .where(end_of_life: 0)
      .where(non_saleable: 0)
  end

  def get_assembly p_id
    assy = get_all
      .where(Sequel.lit('parts_cost > 0'))
      .where(p_id: p_id)
      .first
    return assy.nil? ? Product.new : assy
  end

  def get_available_at_location location
    Product
      .select_group(:products__p_id, :products__p_name, :buy_cost, :sale_cost, :ideal_markup, :real_markup, :price, :price_pro, :direct_ideal_stock, :indirect_ideal_stock, :ideal_stock, :stock_deviation, :stock_store_1, :stock_warehouse_1, :stock_warehouse_2, :products__img, :products__c_id, :products__br_id, :sku)
      .where(archived: 0)
      .left_join(:categories, [:c_id])
      .left_join(:items, products__p_id: :items__p_id, i_status: "READY", i_loc: location.to_s)
      .join(:brands, [:br_id])
      .select_append{:brands__br_name}
      .select_append{:categories__c_name}
      .select_append{ Sequel.case( {{Sequel.lit('real_markup / ideal_markup') => nil} => 0}, Sequel.lit('(real_markup * 100 / ideal_markup) - 100') ).as(markup_deviation_percentile)}
      .select_append{count(i_id).as(qty)}
      .group(:products__p_id, :products__p_name, :buy_cost, :sale_cost, :ideal_markup, :real_markup, :price, :price_pro, :direct_ideal_stock, :indirect_ideal_stock, :ideal_stock, :stock_deviation, :stock_store_1, :stock_warehouse_1, :stock_warehouse_2, :products__img, :products__c_id, :categories__c_name, :products__br_id, :brands__br_name, :sku)
  end

  def get_saleable_at_location location
    get_available_at_location(location)
      .where(non_saleable: 0)
  end

  def deprecated_update_stock_of_products products = nil
    products = get_all_but_archived.order(:categories__c_name, :products__p_name) if products.nil?
    new_products = []
    products.map do |product|
      product.update_stocks
      new_products << product
    end
    new_products
  end

end
