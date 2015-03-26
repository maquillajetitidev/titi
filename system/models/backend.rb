# coding: utf-8
require 'sinatra/flash'
require_relative 'sinatra/auth'
require_relative 'sinatra/my_flash'

class Backend < AppController
  register Sinatra::Auth
  register Sinatra::Flash
  set :name, "Backend"
  helpers ApplicationHelper

  before do
    set_locale
    unprotected_routes = ["/admin/login", "/admin/logout", "sales/login", "sales/logout"]
    protected! unless (unprotected_routes.include? request.env["REQUEST_PATH"]) or request.env["REQUEST_PATH"].nil?
  end

  get '/?' do
    protected! # needed by cucumber
    @orders = Order.new.get_packaging_orders
    slim :admin, layout: :layout_backend
  end

  Dir["controllers/backend/*.rb"].each { |file| require_relative file }


  get '/logs' do
    @logs = ActionsLog.select(:at, :msg, :lvl, :b_id, :m_id, :i_id, :p_id, :o_id, :u_id, :l_id, :username).join(:users, user_id: :u_id).order(:id).reverse.all
    slim :logs, layout: :layout_backend
  end

  run! if __FILE__ == $0

end
