class Backend < AppController

  post '/materials/update_ideal_stocks' do
    Material.order(:m_name).all.each do |material|
      enqueue material
    end

    flash[:warning] = R18n.t.materials.updating_in_background
    redirect to("/materials")
  end

  post '/materials/:m_id/ajax_add_distributor/:d_id' do
    material = Material.new.get_by_id params[:m_id].to_i, current_location[:name]
    if State.current_user.can_edit_materials?
      return "#{h t.material.missing params[:m_id].to_s}" if material.empty?
      distributor = Distributor.new.get params[:d_id].to_i
      return "#{h t.distributor.missing params[:d_id].to_s}" if distributor.empty?
      begin
        distributor.add_material material.m_id
      rescue Sequel::UniqueConstraintViolation
        distributor.remove_material material.m_id
      end
    end
    slim :item_distributors, layout: false, locals: {i_distributors: material.distributors.all}
  end

  get '/materials' do
    @materials = Material.new
                  .get_list(current_location[:name])
                  .all
    @materials.map do |material|
      material[:distributors] = material.distributors.all
    end
    slim :materials, layout: :layout_backend, locals: {title: t.materials.title}
  end
  post '/materials/new' do
    if State.current_user.can_edit_materials?
      begin
        m_id = Material.new.create_default
        flash[:notice] = R18n.t.material.created
        redirect to("/materials/#{m_id}")
      rescue Sequel::UniqueConstraintViolation => e
        puts e.message
        material = Material.filter(m_name: R18n.t.material.default_name).first
        flash[:warning] = R18n.t.material.there_can_be_only_one_new
        redirect to("/materials/#{material[:m_id]}")
      end
    else
      flash[:error] = "No tenes permisos para crear materiales"
      redirect to("/materials")
    end
  end
  get '/materials/:id' do
    @material = Material.new.get_by_id params[:id].to_i, current_location[:name]
    redirect_if_nil_material @material, params[:id].to_i, "/materials"
    @material.calculate_ideal_stock
    @materials_categories = MaterialsCategory.all
    @bulks = @material.bulks current_location[:name]
    @products = @material.products
    @distributors = Distributor.order(:d_name).all
    @i_distributors = @material.distributors.order(:d_name).all
    slim :material, layout: :layout_backend
  end
  put '/materials/:id' do
    material = Material[params[:id].to_i]
    material.update_from_hash(params)
    if material.valid?
      material.save();
      flash[:notice] = t.material.updated
    else
      flash[:error] = material.errors
    end
    redirect to("/materials/#{material[:m_id]}")
  end

  get '/bulks' do
    @bulks = Bulk.new.get_bulks_at_location(current_location[:name]).order(:m_name).all
    @count = 0
    @bulks.map { |bulk| @count += 1 unless bulk.b_printed }
    slim :bulks, layout: :layout_backend, locals: {title: t.bulks.title}
  end
  post '/bulks/labels/csv' do
    require 'tempfile'
    barcodes = Bulk.new.get_as_csv current_location[:name]
    tmp = Tempfile.new(["barcodes", ".csv"])
    tmp << barcodes
    tmp.close
    send_file tmp.path, filename: 'bulks.csv', type: 'octet-stream', disposition: 'attachment'
    tmp.unlink
  end

  get '/bulks/:b_id' do
    @bulk = Bulk[params[:b_id]]
    @material = @bulk.material if @bulk
    slim :bulk, layout: false
  end
  put '/bulks/:b_id' do
    bulk = Bulk[params[:b_id]].update_from_hash(params)
    if bulk.valid?
      bulk.save()
      flash[:notice] = t.bulk.updated
      redirect to("/materials/#{bulk[:m_id]}")
    else
      flash[:error] = bulk.errors
      redirect to("/materials/#{bulk[:m_id]}")
    end
  end
  post '/bulks/new' do
    material = Material[params[:m_id].to_i]
    Bulk.new.create params[:m_id].to_i, material[:m_price], current_location[:name]
    redirect to("/materials/#{params[:m_id].to_i}")
  end
end
