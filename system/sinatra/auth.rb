require 'sinatra/base'
require 'sinatra/flash'
require 'sinatra/extension'
require_relative "../models/user"

module Sinatra
  extend Sinatra::Extension

  module Auth
    module Helpers

      def authorized?
        user = session[:user_id] ? User.new.get_by_id(session[:user_id]) : User.new
        State.current_user = user
        State.current_location = session[:current_location]
        session[:user_id]
      end

      def protected!
        unless authorized?
          flash[:warning] = t.auth.must_login
          halt 401, slim(:admin_login, locals: {login_path: session[:login_path]})
        end
      end
      def set_user user, location
        session[:user_id] = user.user_id
        session[:current_location] = location
        State.current_user = user
        State.current_location = location
      end
      def unset_user
        session.keys.each { |key| session[key] = nil}
        State.clear
      end
    end

    def self.registered(app)
      app.helpers Helpers

      app.get '/login' do
        if session[:user_id]
          user_real_name = State.current_user.user_real_name
        else
          flash[:warning] = t.auth.must_login
        end
        redirect to(session[:root_path]) if authorized?
        slim :admin_login, locals: {login_path: session[:login_path], user_real_name: user_real_name}
      end
      app.post '/login' do
        user = User.new.valid?(params[:admin_username], params[:admin_password])
        location = Location.new.valid?(params[:location]) ? Location.new.get(params[:location]) : false
        if user && location && user.level >= location[:level]
          set_user user, location
          message = t.auth.loggedin(user.username)
          flash[:notice] = message
          enqueue ActionsLog.new.set(msg: message, u_id: user[:user_id], l_id: location[:name], lvl: ActionsLog::NOTICE)
          if (request.env["REQUEST_PATH"].nil? or request.env["HTTP_HOST"].nil? or request.referer.nil?) and not request.referer.nil? and not request.referer.inclue?(request.env["HTTP_HOST"])
            redirect to(session[:root_path])
          else
            redirect to(request.referer)
          end
        else
        root_path = session[:root_path]
        unset_user
        flash[:error] = t.auth.invalid
        redirect to(root_path)
        end
      end
      app.get '/logout' do
        root_path = session[:root_path]
        unset_user
        session.keys.each { |key| session[key] = nil}
        flash[:notice]  = t.auth.loggedout
        redirect to(root_path)
      end

    end
  end
  register Auth
end
