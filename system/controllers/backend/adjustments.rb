# coding: UTF-8

class Backend < AppController

  route :get, :post, '/administration/adjustments/products/by_filter' do
    upf = Update_products_by_filter.new(params, settings.price_updated_at_threshold)
    if upf.mod === false
      flash[upf.flash_level] = upf.flash
      redirect to('/administration')
    elsif upf.mod
      upf.update_products_by_filter
      flash.now[upf.flash_level] = upf.flash if upf.flash
    end
    slim :update_products_by_filter, layout: :layout_backend, locals: {sec_nav: :nav_administration, mod: upf.mod, days: upf.days, products: upf.products}
  end

  class Update_products_by_filter
    @br_id = false
    @d_id = false
    @p_name = false
    @products = []
    @attribute = nil
    @mod = nil
    @save = false
    @price_updated_at_threshold = 0
    @flash = nil
    @flash_level = nil
    attr_reader :products, :mod, :flash, :flash_level

    def initialize params, price_updated_at_threshold
      @br_id = params['br_id'].to_i > 0 ? params['br_id'].to_i : false
      @d_id = params['d_id'].to_i > 0 ? params['d_id'].to_i : false
      @p_name = params['p_name'].to_s.empty? ? false : params['p_name'].to_s
      @attribute = params['attribute'].to_sym if params['attribute']
      @price_updated_at_threshold = params['days'] ? params['days'].to_i : price_updated_at_threshold
      @save = params[:confirm] == R18n.t.products.update_by_filter.submit_text
      @mod = set_mod_from_params params
      @products = get_products_by_filter if @mod
      self
    end

    def days
      return @price_updated_at_threshold.to_i
    end

    def update_products_by_filter
      mod_products
      save_modded_products if @save
      @flash = "Atributo actualizado con un indice de #{mod.to_f}" if @save
      @flash_level = :notice
      self
    end

    def mod_products
      final_products = []
      @products.map do |product|
        if @attribute == :price
          product.price_mod(@mod)
          product.buy_cost_mod( 1 )
        elsif @attribute == :buy_cost
          product.price_mod( 1 )
          product.buy_cost_mod(@mod)
        end
        final_products << product
      end
      @products = final_products
      self
    end

    def save_modded_products
      DB.transaction do
        brand_message = @br_id ? " con marca #{Brand[@br_id].br_name}"  : ""
        current_user_id =  User.new.current_user_id
        message = "Actualizancion masiva de #{eval("R18n.t.product.fields.#{@attribute.to_s}")} de productos#{brand_message}. multiplicador: #{@mod.to_f}"
        ActionsLog.new.set(msg: message, u_id: current_user_id, l_id: "GLOBAL", lvl: ActionsLog::NOTICE).save

        @products.map do |product|
          message = "Precio ajustado *#{@mod.to_s("F")} de $ #{product[:new_price].to_s("F")} a $ #{product.price.to_s("F")}: #{product.p_name}" if @attribute == :price
          message = "Costo de compra ajustado *#{@mod.to_s("F")} de $ #{product[:new_buy_cost].to_s("F")} a $ #{product.buy_cost.to_s("F")}: #{product.p_name}" if @attribute == :buy_cost
          ActionsLog.new.set(msg: message, u_id: current_user_id, l_id: "GLOBAL", lvl: ActionsLog::INFO, p_id: product.p_id).save
          product.save verify: false
        end
      end
    end

    def check_mod mod
      if mod.to_s.empty?
        @flash = "Tenes que decirme por cuanto multiplicar."
      elsif mod == "0"
        @flash = "Multiplicar por cero no es una buena idea."
      elsif mod.to_f <= 0
        @flash = "Que estas intentando probar?."
      else
        return true
      end
      @flash_level = :warning
      false
    end

    def set_mod_from_params params
      return nil if params[:mod].nil?
      return check_mod(params[:mod].to_s.gsub(',', '.')) ? BigDecimal.new(params[:mod], 2) : false
    end

    private
      def get_products_by_filter
        threshold = Sequel.date_sub(Time.now.getlocal("-00:03").to_date.iso8601, {days: days-1})
        products = Product.new.get_all.where{Sequel.expr(:products__price_updated_at) < threshold}.where(archived: 0)
        products = products.join(:products_to_distributors, [:p_id]).join(:distributors, [:d_id]).where(d_id: @d_id) if @d_id
        products = products.where(br_id: @br_id) if @br_id
        products = products.where("p_name LIKE :p_name", p_name: "%#{@p_name}%") if @p_name
        products.all
      end
  end






  route :get, :post, '/administration/adjustments/materials/by_filter' do
    upf = Update_materials_by_filter.new(params, settings.price_updated_at_threshold)
    if upf.mod === false
      flash[upf.flash_level] = upf.flash
      redirect to('/administration')
    elsif upf.mod
      upf.update_materials_by_filter
      flash.now[upf.flash_level] = upf.flash if upf.flash
    end
    slim :update_materials_by_filter, layout: :layout_backend, locals: {sec_nav: :nav_administration, mod: upf.mod, materials: upf.materials}
  end

  class Update_materials_by_filter
    @br_id = false
    @d_id = false
    @m_name = false
    @materials = []
    @attribute = nil
    @mod = nil
    @save = false
    @price_updated_at_threshold = 0
    @flash = nil
    @flash_level = nil
    attr_reader :materials, :mod, :flash, :flash_level

    def initialize params, price_updated_at_threshold
      @br_id = params['br_id'].to_i > 0 ? params['br_id'].to_i : false
      @d_id = params['d_id'].to_i > 0 ? params['d_id'].to_i : false
      @m_name = params['m_name'].to_s.empty? ? false : params['m_name'].to_s
      @attribute = params['attribute'].to_sym if params['attribute']
      @price_updated_at_threshold = price_updated_at_threshold
      @save = params[:confirm] == R18n.t.materials.update_by_filter.submit_text
      @mod = set_mod_from_params params
      @materials = get_materials_by_filter if @mod
      self
    end

    def update_materials_by_filter
      mod_materials
      save_modded_materials if @save
      @flash = "Atributo actualizado con un indice de #{mod.to_f}" if @save
      @flash_level = :notice
      self
    end

    def mod_materials
      final_materials = []
      @materials.map do |material|
        material.price_mod(@mod)
        final_materials << material
      end
      @materials = final_materials
      self
    end

    def save_modded_materials
      DB.transaction do
        brand_message = @br_id ? " con marca #{Brand[@br_id].br_name}"  : ""
        current_user_id =  User.new.current_user_id
        message = "Actualizancion masiva de #{eval("R18n.t.material.fields.#{@attribute.to_s}")} de materialos#{brand_message}. multiplicador: #{@mod.to_f}"
        ActionsLog.new.set(msg: message, u_id: current_user_id, l_id: "GLOBAL", lvl: ActionsLog::NOTICE).save

        @materials.map do |material|
          message = "Costo de compra ajustado *#{@mod.to_s("F")} de $ #{material[:new_buy_cost].to_s("F")} a $ #{material.m_price.to_s("F")}: #{material.m_name}" if @attribute == :price
          ActionsLog.new.set(msg: message, u_id: current_user_id, l_id: "GLOBAL", lvl: ActionsLog::INFO, m_id: material.m_id).save
          material.save verify: false
        end
      end
    end

    def check_mod mod
      if mod.to_s.empty?
        @flash = "Tenes que decirme por cuanto multiplicar."
      elsif mod == "0"
        @flash = "Multiplicar por cero no es una buena idea."
      elsif mod.to_f <= 0
        @flash = "Que estas intentando probar?."
      else
        return true
      end
      @flash_level = :warning
      false
    end

    def set_mod_from_params params
      return nil if params[:mod].nil?
      return check_mod(params[:mod].to_s.gsub(',', '.')) ? BigDecimal.new(params[:mod], 2) : false
    end

    private
      def get_materials_by_filter
        threshold = Sequel.date_sub(Time.now.getlocal("-00:03").to_date.iso8601, {days: @price_updated_at_threshold})
        materials = Material.new.get_list([Location::W1, Location::W2]).where{Sequel.expr(:materials__price_updated_at) < threshold}
        materials = materials.join(:materials_to_distributors, materials_to_distributors__m_id: :materials__m_id).join(:distributors, [:d_id]).where(d_id: @d_id) if @d_id
        materials = materials.where("m_name LIKE :m_name", m_name: "%#{@m_name}%") if @m_name
        materials.all
      end
  end





  route :get, :put, '/administration/adjustments/products/by_sku' do
    products = []
    missing_skus = []
    unless params[:raw_data].nil?
      sku_cols = get_sku_cols params
      rows = clean_tabbed_data params[:raw_data]
      rows.each do |row|
        sku = get_sku_from_row row, sku_cols

        product = Product.new.get_by_sku sku
        missing_skus << sku if product.empty? unless sku.empty?
        unless product.empty?

          new_buy_cost = params[:buy_cost_on].empty? ? 0 : BigDecimal.new(Utils::as_number(row[params[:buy_cost_on].to_i]), 4)
          product[:new_buy_cost] = new_buy_cost > 0 ? new_buy_cost : product.buy_cost

          new_ideal_markup = params[:ideal_markup_on].empty? ? 0 : BigDecimal.new(Utils::as_number(row[params[:ideal_markup_on].to_i]), 4)
          product[:new_ideal_markup] = new_ideal_markup > 0 ? new_ideal_markup : product.ideal_markup

          new_price = params[:price_on].empty? ? 0 : BigDecimal.new(Utils::as_number(row[params[:price_on].to_i]), 4)
          product[:new_price] = new_price > 0 ? new_price : product.price

          products << product
          if params[:confirm]
            p = product.dup
            p.buy_cost = product[:new_buy_cost]
            p.ideal_markup = product[:new_ideal_markup]
            p.price = product[:new_price]
            p.recalculate_markups
            p.save
          end
        end
      end
      flash.now['error'] = {"#{t.products.update_by_sku.errors_found missing_skus.size}".to_sym => missing_skus} unless missing_skus.empty?
    end
    slim :update_products_by_sku, layout: :layout_backend, locals: {sec_nav: :nav_administration, products: products, missing_skus: missing_skus}
  end


  route :get, :put, '/administration/adjustments/materials/by_sku' do
    materials = []
    missing_skus = []
    unless params[:raw_data].nil?
      sku_cols = get_sku_cols params
      rows = clean_tabbed_data params[:raw_data]
      rows.each do |row|
        sku = get_sku_from_row row, sku_cols

        material = Material.new.get_by_sku sku
        missing_skus << sku if material.empty? unless sku.empty?
        unless material.empty?

          new_m_price = params[:m_price_on].empty? ? 0 : BigDecimal.new(Utils::as_number(row[params[:m_price_on].to_i]), 6)
          material[:new_m_price] = new_m_price > 0 ? new_m_price : material.m_price

          materials << material
          if params[:confirm]
            m = material.dup
            m.m_price = material[:new_m_price]
            m.save
          end
        end
      end
      flash.now['error'] = {"#{t.materials.update_by_sku.errors_found missing_skus.size}".to_sym => missing_skus} unless missing_skus.empty?
    end
    slim :update_materials_by_sku, layout: :layout_backend, locals: {sec_nav: :nav_administration, materials: materials, missing_skus: missing_skus}
  end

  def get_sku_from_row row, sku_cols
    sku = row.select.with_index{ |col, i| col if sku_cols.include? i }.reject(&:empty?).join('')
    sku = sku.to_s.gsub(/\n|\r|\t/, '').squeeze(" ").strip
    sku
  end

  def get_sku_cols params
    sku_cols = []
    keys = {sku_on_a: 0, sku_on_b: 1, sku_on_c: 2}
    params.select { |key, value| sku_cols << keys[key.to_sym] if keys.has_key? key.to_sym }
    sku_cols
  end

  def clean_tabbed_data raw
    raw.to_s.split("\n").collect { |row| row.split("\t").collect{ |col| col.gsub(/\n|\r|\t/, '').squeeze(" ").strip} }.uniq { |s| s.first }
  end
end
