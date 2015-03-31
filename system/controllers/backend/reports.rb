require_relative '../shared/logs'

class Backend < AppController
  include Logs
  require 'descriptive_statistics'

  DescriptiveStatistics.empty_collection_default_value = 0.0

  get '/administration/reports/montly' do
    sales_report = []
    Product.new.get_live.order(:p_name).all.each do |product|
      raw_sales = DB.fetch("
          select p_id, DATE_FORMAT(orders.created_at,'%y%m') as date, count(1) as qty
          from orders
          join line_items using (o_id)
          join items using (i_id)
          where type = 'SALE' and p_id = #{product.p_id}
          group by p_id, date
          order by p_id, date
        ").all
      raw_sales ||= []
      sales = {}
      months_with_activity = []
      raw_sales.each do |month|
        sales[month[:date]] = month[:qty]
        months_with_activity << month[:qty] if month[:qty] > 0
      end
      last_six_months = months_with_activity.last 6
      sales[:median] = last_six_months.median
      sales[:standard_deviation] = last_six_months.standard_deviation
      sales[:recomended] = ((sales[:median] + (sales[:standard_deviation] / 2)) * 2).round / 2.0

      product[:sales] = sales
      product[:distributors] = product.distributors
      sales_report << product
    end

    slim :sales_report, layout: :layout_backend, locals: {
      title: "reporte de ventas", sec_nav: :nav_administration,
      products: sales_report,
      months: prev_year_months
    }
  end

  get '/administration/reports/price_list' do
    products = Product.new.get_live.order(:categories__c_name, :products__p_name).all

    slim :products_list, layout: :layout_backend, locals: {
      title: "Lista de precios", sec_nav: :nav_administration,
      status_col: true,
      price_pro_col: false,
      show_filters: false,
      products: products
    }
  end

  route :get, '/administration/reports/logins/:username' do
    get_and_render_logins params[:username]
  end

  get '/administration/reports/products_flags' do
    products = Product.new.get_all.order(:categories__c_name, :products__p_name).all
    slim :products_list, layout: :layout_backend, locals: {
      title: "Reporte de flags", sec_nav: :nav_administration,
      show_edit_button: true, edit_link: :edit_product,
      price_col: true,
      price_pro_col: false,
      stock_col: false,
      price_updated_at_col: true,
      flags_cols: true,
      products: products
    }
  end

  get '/administration/reports/markups' do
    products = Product.new.get_live.all
    products.sort_by! { |product| product[:markup_deviation_percentile] }
    slim :products_list, layout: :layout_backend, locals: {
      title: "Reporte de markups", sec_nav: :nav_administration,
      show_edit_button: true, edit_link: :edit_product,
      price_pro_col: false,
      stock_col: false,
      real_markup_col: true,
      ideal_markup_col: true,
      markup_deviation_percentile_col: true,
      price_updated_at_col: true,
      products: products
    }
  end

  get '/production/reports/to_package/:mode' do
    products = Product.new.get_all.where(archived: false, tercerized: false, end_of_life: false).all

    mode = params[:mode].upcase
    locations = mode.include?("STORE_ONLY") ? BigDecimal.new(1) : BigDecimal.new(2)
    months = BigDecimal.new(mode[-1])

    products.map do |product|
      if locations == 1
        product[:ideal_for_period] = product.supply.stores_ideal * months
        product[:deviation_for_period] = product.supply.stores_future - product[:ideal_for_period]
      else
        product[:ideal_for_period] = product.supply.global_ideal * months
        product[:deviation_for_period] = product.supply.global_future - product[:ideal_for_period]
      end
      product[:deviation_for_period] = BigDecimal.new(0) if product[:deviation_for_period].nan?
      product[:deviation_for_period_percentile] = product[:deviation_for_period] * 100 / product[:ideal_for_period]
      product[:deviation_for_period_percentile] = BigDecimal.new(0) if product[:deviation_for_period_percentile].nan?
    end

    products.delete_if { |product| product[:deviation_for_period_percentile] >= 0} # don't overpackage
    products.sort_by! { |product| [ product[:deviation_for_period_percentile], product[:deviation_for_period] ] }
    slim :products_list, layout: :layout_backend, locals: {
      title: "Reporte de productos por envasar", sec_nav: :nav_production,
      show_hide_button: true,
      brand_col: false,
      full_row: true,
      price_col: false,
      price_pro_col: false,
      multi_stock_col: true,
      show_future_availability: true,
      deviation_for_period_col: true,
      months: months,
      locations: locations,
      products: products
    }
  end

  route :get, :post, '/administration/reports/materials_to_buy' do
    months = params[:months].to_i unless params[:months].nil? || params[:months] == 0
    months ||= settings.desired_months_worth_of_bulk_in_warehouse
    materials = Material.new.get_list([Location::W1, Location::W2]).all
    materials.map do |material|
      material.update_stocks
      material.recalculate_ideals months
      material[:distributors] = material.distributors.all
    end
    materials.delete_if { |material| material[:stock_deviation_percentile] >= 0} # don't overbuy
    materials.sort_by! { |material| [ material[:stock_deviation_percentile], material[:stock_deviation] ] }
    slim :reports_materials_to_buy, layout: :layout_backend, locals: {
      title: R18n.t.reports_materials_to_buy(months), sec_nav: :nav_administration,
      months: months,
      materials: materials
    }
  end

  route :get, :post, '/production/reports/products_to_move_s1' do
    months = params[:months].to_i unless params[:months].nil?
    months ||= settings.desired_months_worth_of_items_in_store
    products ||= []
    raw_products = Product.new.get_all.where(archived: false, non_saleable: false).all
    raw_products.each do |product|
      product[:ideal_for_period] = product.supply.s1_whole_ideal * months
      product[:missing_for_period] = product[:ideal_for_period] >= product.supply.s1_whole_future ? product[:ideal_for_period] - product.supply.s1_whole_future : BigDecimal.new(0)
      product[:deviation_for_period] = product.supply.s1_whole_future - product[:ideal_for_period]
      product[:deviation_for_period] = BigDecimal.new(0) if product[:deviation_for_period].nan?
      product[:deviation_for_period_percentile] = product[:deviation_for_period] * 100 / product[:ideal_for_period]
      product[:deviation_for_period_percentile] = BigDecimal.new(0) if product[:deviation_for_period_percentile].nan?
      avail_in_warehouses = product.supply.warehouses_whole_future
      product[:to_move] = product[:missing_for_period] >= avail_in_warehouses ? avail_in_warehouses : product[:missing_for_period]
      if avail_in_warehouses > 0 && (product.end_of_life || product.ideal_stock == 0)
        product[:deviation_for_period] = avail_in_warehouses * -1
        product[:deviation_for_period_percentile] = -100
        product[:to_move] = avail_in_warehouses
      end
      products << product if product[:deviation_for_period_percentile] < settings.reports_percentage_threshold && avail_in_warehouses > 0
    end
    products.sort_by! { |product| [ product[:deviation_for_period_percentile], product[:deviation_for_period] ] }
    slim :reports_products_to_move, layout: :layout_backend, locals: {
      title: R18n.t.reports_products_to_move(months, current_location[:translation]), sec_nav: :nav_production,
      products: products,
      months: months,
      locations: 1
    }
  end

  route :get, :post, '/administration/reports/products_to_buy' do
    months = params[:months].to_i unless params[:months].nil?
    months ||= settings.desired_months_worth_of_items_in_store
    products ||= []
    # antes estaba limitado a 50 y por eso no le traia todos
    #raw_products = Product.new.get_all.where(archived: false, tercerized: true, end_of_life: false, on_request: false).limit(50).all
    raw_products = Product.new.get_all.where(archived: false, tercerized: true, end_of_life: false, on_request: false).all

    distributors = Distributor.all

    total_cost = 0
    raw_products.each do |product|
      product[:ideal_for_period] = product.supply.global_ideal * months
      product[:deviation_for_period] = product.supply.global_future - product[:ideal_for_period]
      product[:deviation_for_period] = (-1...0) == product[:deviation_for_period] ? product[:deviation_for_period].floor(1) : product[:deviation_for_period].round(0)
      product[:deviation_for_period_percentile] = product[:deviation_for_period] * 100 / product[:ideal_for_period]

      product[:deviation_for_period] = BigDecimal.new(0) if product[:deviation_for_period].nan?
      product[:deviation_for_period_percentile] = BigDecimal.new(0) if product[:deviation_for_period_percentile].nan?

      product[:total_cost] = product[:deviation_for_period] < 0 ? product.buy_cost * product[:deviation_for_period] * -1 : 0
      total_cost += product[:total_cost]

      if product.distributors.first
        distributors.map do |distributor|
          if distributor.d_id == product.distributors.first.d_id
            distributor[:ideal_for_period] = product.supply.global_ideal * months
            distributor[:deviation_for_period] = product.supply.global_whole - distributor[:ideal_for_period]
            distributor[:ponderated_deviation] = (distributor[:deviation_for_period] / distributor[:ideal_for_period]) * 100
            product[:distributor] = distributor
          end
        end
      else
        product[:distributor] = Distributor.new
        product[:distributor][:ideal_for_period] = 0
        product[:distributor][:deviation_for_period] = 0
        product[:distributor][:ponderated_deviation] = 0
        product[:distributor][:ponderated_deviation] = -999
      end
      products << product if product[:deviation_for_period] < 0
    end

    products.sort_by! { |product| [ product[:distributor][:ponderated_deviation], product.inventory(months).global.v_deviation_percentile, product.inventory(months).global.v_deviation ] }

    slim :reports_products_to_buy, layout: :layout_backend, locals: {
      title: R18n.t.reports_products_to_buy(months), sec_nav: :nav_administration,
      months: months,
      locations: 2,
      total_cost: total_cost,
      products: products
    }
  end
end
