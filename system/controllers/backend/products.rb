class Backend < AppController

  route :get, :post, '/inventory/samplify_items' do
    if params[:i_ids].nil?
      slim :samplify_items, layout: :layout_backend, locals: {
        title: t.samplify_items.title,
        sec_nav: :nav_administration
      }
    else
      samplify_items
    end
  end

  # Se fija si ya existe una muestra de este mismo p_id, y si existe la/las anula
  def void_old_samples item
    existent = Item.filter(i_status: Item::SAMPLE, p_id: item.p_id).all
    existent.each do |itemToVoid|
      itemToVoid.void! "Se genera nueva muestra de este producto con el item id #{item[:i_id]}"
    end
  end

  def samplify_items
    i_ids = Item.new.split_input_into_ids(params[:i_ids])
    items = Item.filter(i_id: i_ids).all
    errors = Item.new.check_io(i_ids, items)
    unless errors.empty?
      flash[:error] = "Algunos ID especificados son invalidos #{errors.flatten.to_s}"
      redirect to('/inventory/samplify_items')
      return false
    end
    items.each do |item|
      if !item.inStore then
        flash[:error] = "El item con ID #{item.i_id} no esta en el local. Se cancela la operacion."
        redirect to('/inventory/samplify_items')
        return false
      end
    end
    begin
      messages = []
      items.each do |item|
        if void_old_samples(item) then
          messages << item.samplify!
        end
      end
      flash.now[:notice] = messages.flatten.to_s
      slim :samplify_items, layout: :layout_backend, locals: {
        title: "Conversion a muestra correcta",
        sec_nav: :nav_administration,
        items: items
      }
    rescue SecurityError => e
      flash[:error] = e.message
      redirect to('/inventory/samplify_items')
    rescue => e
      flash[:error] = e.message
      redirect to('/inventory/samplify_items')
    end
  end

  post '/products/update_all' do
    Product.order(:p_name).all.each { |product| enqueue product }
    flash[:warning] = R18n.t.products.updating_in_background
    redirect to("/")
  end

  post '/products/:p_id/ajax_add_distributor/:d_id' do
    product = Product.new.get params[:p_id].to_i
    return "#{h t.product.missing params[:p_id].to_s}" if product.empty?
    distributor = Distributor.new.get params[:d_id].to_i
    return "#{h t.distributor.missing params[:d_id].to_s}" if distributor.empty?
    begin
      distributor.add_product product.p_id
    rescue Sequel::UniqueConstraintViolation
      distributor.remove_product product.p_id
    end
    slim :item_distributors, layout: false, locals: {i_distributors: product.distributors.all}
  end

  get '/products/sku' do
    products = Product.new.get_live.order(:c_name, :p_name).all
    slim :products_list, layout: :layout_backend, locals: {full_row: false, sku_col: true, show_edit_button: true, edit_link: :edit_product, title: R18n.t.products.sku_editor.title, caption: R18n.t.products.sku_editor.caption, products: products}
  end

  post '/products/ajax_update' do
    case params[:function]
      when "update_sku"
        sku = params[:value]
        product = Product.new.get params[:id].to_i
        product.sku= sku
        product.save
        return product.errors.to_a.flatten.join(": ") if product.errors.count > 0
        p product.sku
    end
  end

  get '/products/categories' do
    @categories = Category.all
    slim :categories, layout: :layout_backend, locals: {title: t.categories.title}
  end

  get '/products/categories/:id' do
    @category = Category.new.get_by_id params[:id].to_i
    slim :category, layout: :layout_backend
  end

  put '/products/categories/:c_id' do
    category = Category[params[:c_id].to_i].update_from_hash(params)
    if category.valid?
      category.save()
      flash[:notice] = R18n.t.category.updated
    else
      flash[:error] = category.errors
    end
    redirect to("/products/categories/#{category.c_id}")
  end

  def void_items
    i_ids = Item.new.split_input_into_ids(params[:i_ids])
    items = Item.filter(i_id: i_ids).all
    errors = Item.new.check_io(i_ids, items)
    unless errors.empty?
      flash[:error] = "Algunos ID especificados son invalidos #{errors.flatten.to_s}"
      redirect to('/inventory/void_items')
      return false
    end

    begin
      messages = []

      items.each { |item| messages << item.void!(params[:reason]) }
      flash.now[:notice] = messages.flatten.to_s
      @title = "Anulacion correcta"
      @items = items
      slim :void_items, layout: :layout_backend, locals: {sec_nav: :nav_administration}
    rescue SecurityError => e
      flash[:error] = e.message
      redirect to('/inventory/void_items')
    rescue => e
      flash[:error] = e.message
      redirect to('/inventory/void_items')
    end
  end

  route :get, :post, '/inventory/void_items' do
    if params[:i_ids].nil? and params[:reason].nil?
      slim :void_items, layout: :layout_backend, locals: {sec_nav: :nav_administration}
    else
      void_items
    end
  end


  def set_locals_for_transmutation
    if params[:i_id]
      @item = Item.new.get_for_transmutation params[:i_id]
      flash[:error] = @item.errors unless @item.errors.empty?
      redirect to('/inventory/transmute_items') unless @item.errors.empty?
      @product = Product[@item.p_id]
      @products = Product.new.get_all_but_archived.order(:c_name, :p_name).all
    end
    @item ||= Item.new
    @product ||= Product.new
    @products ||= []
    {item: @item, product: @product, products: @products}
  end

  route :get, :post, '/inventory/transmute_items' do
    locals = set_locals_for_transmutation
    @item = locals[:item]
    @product = locals[:product]
    @products = locals[:products]
    slim :transmute_items_check, layout: :layout_backend, locals: {sec_nav: :nav_administration}
  end

  route :get, '/inventory/transmute_items/:i_id/:p_id' do
    locals = set_locals_for_transmutation
    @item = locals[:item]
    @product = locals[:product]
    @new_product = Product[params[:p_id].to_i]
    slim :transmute_items, layout: :layout_backend, locals: {sec_nav: :nav_administration}
  end

  route :post, '/inventory/transmute_items/:i_id/:p_id' do
    item = Item[params[:i_id].to_s]
    begin
      item.transmute! params[:reason].to_s, params[:p_id].to_i
      flash[:notice] = "Item Transmutado a #{item.p_name}}"
    rescue => detail
      flash[:error] = detail.message
    end
    redirect to('/inventory/transmute_items')
  end




  get '/products/items' do
    items = Item.new.get_items_at_location current_location[:name]
    slim :items, layout: :layout_backend, locals: {sec_nav: :nav_production, title: t.items.title, items: items}
  end
  get '/products/items/:p_name' do
    p_name = params[:p_name].to_s
    items = Item.new.get_items_at_location(current_location[:name]).where(Sequel.like(:items__p_name, "%#{p_name}%")  )
    slim :items, layout: :layout_backend, locals: {sec_nav: :nav_production, title: t.items.title, items: items}
  end

  get '/products/relationships' do
    products = Product.new.get_all_but_archived.order(:c_name, :p_name).filter(Sequel.lit('parts_cost > 0 OR materials_cost > 0')).all
    @relationships = []
    products.each do |p|
      relationship = {product: p, materials: p.materials, parts: p.parts}
      @relationships << relationship
    end
    slim :products_relations, layout: :layout_backend
  end

  get '/products' do
    products = Product.new.get_available_at_location(current_location[:name]).order(:c_name, :p_name).all
    slim :products, layout: :layout_backend, locals: {stock_col: true, full_row:true, show_edit_button: true, edit_link: :edit_product, title: t.products.title, products: products}
  end

  post '/products/new' do
    begin
      p_id = Product.new.create_default
      flash[:warning] = R18n.t.product.created
      redirect to("/products/#{p_id}")
    rescue Sequel::UniqueConstraintViolation => e
      puts e.message
      product = Product.filter(p_name: "NEW Varias").first
      flash[:warning] = R18n.t.product.there_can_be_only_one_new
      redirect to("/products/#{product[:p_id]}")
    end
  end

  get '/products/:id' do
    edit_product params[:id]
  end

  put '/products/:id' do
    product = Product[params[:id].to_i].update_from_hash(params)
    product.validate
    if product.errors.count == 0  and product.valid?
      product.update_stocks.save
      if product.errors.count == 0  and product.valid?
        flash[:notice] = R18n.t.product.updated
      else
        flash[:error] = product.errors
      end
    else
      flash[:error] = product.errors
    end
    redirect to("/products/#{product[:p_id]}")
  end

  post '/products/:id/dup' do
    product = Product[params[:id].to_i]
    if product.valid?
      dest = product.duplicate
      flash[:notice] = R18n.t.product.duplicated
    else
      flash[:error] = product.errors
    end
    redirect to("/products/#{dest[:p_id]}")
  end

  put '/products/:p_id/materials' do
    p_id = params[:p_id].to_i
    product = Product[p_id]
    redirect_if_nil_product product, p_id, "/products"
    m_id = params[:m_id].to_i
    m_qty = params[:m_qty].to_s.gsub(',', '.').to_f
    material = Material[m_id]
    material[:m_qty] = m_qty
    redirect_if_nil_material material, m_id, "/products/#{p_id}"

    product.update_material material
    redirect_if_nil_product product, p_id, "/products/#{p_id}"

    flash[:notice] = t.product.material_updated material[:m_qty], material[:m_name] if material[:m_qty] > 0
    flash[:notice] = t.product.material_removed material[:m_name] if material[:m_qty] == 0
    redirect to("/products/#{product[:p_id]}#materials")
  end

  post '/products/:p_id/materials/add' do
    p_id = params[:p_id].to_i
    product = Product[p_id]
    redirect_if_nil_product product, p_id, "/products"
    m_id = params[:m_id].to_i
    m_qty = params[:m_qty].to_s.gsub(',', '.').to_f
    material = Material[m_id]
    material[:m_qty] = m_qty
    redirect_if_nil_material material, m_id, "/products/#{p_id}"

    product.add_material material
    redirect_if_nil_product product, p_id, "/products/#{p_id}"

    flash[:notice] = t.product.material_added material[:m_qty], material[:m_name]
    redirect to("/products/#{product[:p_id]}#materials")
  end


  put '/products/:p_id/parts' do
    p_id = params[:p_id].to_i
    product = Product[p_id]
    redirect_if_nil_product product, p_id, "/products"
    part_id = params[:part_id].to_i
    part_qty = params[:part_qty].to_s.gsub(',', '.').to_f
    part = Product[part_id]
    part[:part_qty] = part_qty
    redirect_if_nil_product part, part_id, "/products/#{p_id}"

    product.update_part part
    redirect_if_nil_product product, p_id, "/products/#{p_id}"

    flash[:notice] = t.product.part_updated part[:part_qty], part[:p_name] if part[:part_qty] > 0
    flash[:notice] = t.product.part_removed part[:p_name] if part[:part_qty] == 0
    redirect to("/products/#{product[:p_id]}#parts")
  end

  post '/products/:p_id/parts/add' do
    p_id = params[:p_id].to_i
    product = Product[p_id]
    redirect_if_nil_product product, p_id, "/products"

    part_id = params[:part_id].to_i
    part_qty = params[:part_qty].to_s.gsub(',', '.').to_f
    part = Product[part_id]
    part[:part_qty] = part_qty
    redirect_if_nil_product part, p_id, "/products/#{p_id}"

    product.add_part part
    redirect_if_nil_product product, p_id, "/products/#{p_id}"

    flash[:notice] = t.product.part_added part[:part_qty], part[:p_name]
    redirect to("/products/#{product[:p_id]}#materials")
  end

  def edit_product p_id
    @product = Product.new.get(p_id)
    redirect_if_nil_product @product, p_id, "/products" if @product.empty?
    addedMaterialsIds = []
    ProductsMaterial.where(:product_id => p_id).select(:m_id).all.each do |material|
      addedMaterialsIds << material.values[:m_id]
    end
    @materials = Material.exclude(:m_id => addedMaterialsIds).select(:m_id, :m_name).order(:m_name).all
    addedPartsIds = []
    ProductsPart.where(:product_id => p_id).select(:part_id).all.each do |product|
      addedPartsIds << product.values[:part_id]
    end
    @parts = Product.filter(archived: false, end_of_life: false).exclude(:p_id => addedPartsIds).select(:p_id, :p_name).order(:p_name).all
    @p_parts = @product.parts
    @p_materials = @product.materials
    @p_assemblies = @product.assemblies
    @categories = Category.all
    @brands = Brand.all
    @distributors = Distributor.order(:d_name).all
    @i_distributors = @product.distributors.all
    @product.validate
    flash.now[:error] = @product.errors if @product.errors.count > 0
    slim :product, layout: :layout_backend
  end

end
