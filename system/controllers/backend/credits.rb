class Backend < AppController
  get '/credits/?' do
    @credits = Credit.all
    slim :credits, layout: :layout_backend
  end

  get '/credits/:id' do
    @credit = Credit[params[:id].to_i]
    slim :credit, layout: :layout_backend
  end
end
