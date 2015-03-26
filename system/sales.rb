# coding: utf-8
require 'sinatra/flash'
require_relative 'sinatra/auth'
require_relative 'sinatra/my_flash'
require_relative 'sinatra/csrf'

class Sales < AppController
  register Sinatra::ConfigFile
  config_file File.expand_path '../config.yml', __FILE__

  register Sinatra::Auth
  register Sinatra::Flash
  register Sinatra::Csrf
  apply_csrf_protection

  set :name, "Sales"
  helpers ApplicationHelper

  before do
    if Location.new.warehouses.include? session[:current_location]
      State.clear
      session.each do |key, value|
        p "deleting #{key}"
        session.delete(key.to_sym)
      end
    end

    set_locale
    session[:login_path] = "/sales/login"
    session[:root_path] = "../sales"
    session[:layout] = :layout_sales
    unprotected_routes = ["/admin/login", "/admin/logout", "/sales/login", "/sales/logout"]
    protected! unless (unprotected_routes.include? request.env["REQUEST_PATH"])
  end

  Dir["controllers/sales/*.rb"].each { |file| require_relative file }
  Dir["controllers/shared/*.rb"].each { |file| require_relative file }

  run! if __FILE__ == $0

end

class Ventas < AppController
  set :name, "Ventas"
  helpers ApplicationHelper

  get '/?' do
    redirect to("../sales/logout")
    halt 401, "must login"
  end

  run! if __FILE__ == $0
end
