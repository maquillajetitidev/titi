class Backend < AppController

  get '/distributors' do
    slim :distributors, layout: :layout_backend, locals: {sec_nav: :nav_administration, distributors: Distributor.order(:d_name).all, title: t.distributors.title}
  end

  route :get, :post, '/distributors/new' do
    distributor = Distributor.new.get(params[:id].to_i)
    slim :distributor, layout: :layout_backend, locals: {sec_nav: :nav_administration, distributor: distributor}
  end
  post '/distributors/0' do
    distributor = Distributor.new.update_from_hash(params)
    begin
      save_and_redirect distributor, "/distributors"
    rescue Sequel::UniqueConstraintViolation
      distributor = Distributor.where(d_name: distributor.d_name).last
      flash[:error] = R18n.t.distributor.duplicated_name distributor.d_name
      redirect to("/distributors/#{distributor.d_id}")
    end
  end

  get '/distributors/:id' do
    distributor = Distributor.new.get(params[:id].to_i)
    redirect_if_empty_or_nil distributor, '/distributors'
    slim :distributor, layout: :layout_backend, locals: {sec_nav: :nav_administration, distributor: distributor}
  end

  put '/distributors/:id' do
    distributor = Distributor.new.get(params[:id].to_i)
    redirect_if_empty_or_nil distributor, '/distributors'
    distributor.update_from_hash(params)
    save_and_redirect distributor, "/distributors"
  end

end
