class Sales < AppController

  get '/' do
    protected! # needed by cucumber
    slim :sales, layout: :layout_sales
  end

  get '/products' do
    products = Product.new.get_saleable_at_location(current_location[:name]).order(:c_name, :p_name).all
    slim :products, layout: :layout_sales, locals: {
      title: t.products.title, sec_nav: :nav_products,
      full_row: true,
      stock_col: true,
      show_edit_button: false,
      show_filters: true,
      products: products
    }
  end

  get '/products/items/?' do
    items = Item.new.get_items_at_location_with_status current_location[:name], Item::READY
    slim :items, layout: :layout_sales, locals: {
      title: "Items disponibles", sec_nav: :nav_products,
      show_edit_button: false,
      show_filters: true,
      items: items
    }
  end

end
