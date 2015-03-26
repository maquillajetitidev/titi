# coding: utf-8
require 'sinatra/flash'
require_relative 'sinatra/auth'
require_relative 'sinatra/my_flash'
require_relative 'sinatra/csrf'

class Backend < AppController
  register Sinatra::ConfigFile
  config_file File.expand_path '../config.yml', __FILE__

  register Sinatra::Auth
  register Sinatra::Flash
  register Sinatra::Csrf
  apply_csrf_protection

  set :name, "Backend"
  helpers ApplicationHelper

  before do
    if Location.new.stores.include? session[:current_location]
      State.clear
      session.each do |key, value|
        p "deleting #{key}"
        session.delete(key.to_sym)
      end
    end

    set_locale
    session[:login_path] = "/admin/login"
    session[:root_path] = "../admin"
    session[:layout] = :layout_backend
    unprotected_routes = ["/admin/login", "/admin/logout", "/sales/login", "/sales/logout"]
    protected! unless (unprotected_routes.include? request.env["REQUEST_PATH"])
  end

  Dir["controllers/backend/*.rb"].each { |file| require_relative file }
  Dir["controllers/shared/*.rb"].each { |file| require_relative file }

  run! if __FILE__ == $0

end
