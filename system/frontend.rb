# coding: utf-8

class Frontend < AppController
  set :name, "Frontend"
  helpers ApplicationHelper
  # aggresive caching for frontend
  set :start_time, Time.now
  before do
    last_modified settings.start_time
    etag settings.start_time.to_s
    cache_control :public, :must_revalidate
  end

  get '/' do
    slim :home, layout: :layout_frontend
  end

  get '/contacto/' do
    slim :contacto, layout: :layout_frontend
  end

  get '/fotos/' do
    slim :fotos, layout: :layout_frontend, locals: {gallery: Gallery.all.reverse}
  end

  get '/productos/' do
    slim :frontend_categories, layout: :layout_frontend, locals: {categories: Category.all}
  end

  get '/productos/cat/:cat_id' do
    slim :frontend_category, layout: :layout_frontend, locals: {category: Category[params[:cat_id]], products: Product.new.get_live.where(c_id: params[:cat_id]).all}
  end

  get '/productos/:id' do
    @category = Category[params[:id].to_i]
    slim :category, layout: :layout_frontend
  end

end
