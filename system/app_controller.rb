# coding: utf-8
Encoding.default_internal = 'utf-8'
Encoding.default_external = 'utf-8'
require 'sinatra/base'
require 'sequel'
require 'slim'
require "awesome_print"
require 'sinatra/r18n'
require "sinatra/multi_route"
require "i18n"


require_relative 'helpers/init'
require_relative 'models/init'

class AppController < Sinatra::Base

  register Sinatra
  register Sinatra::ConfigFile
  config_file '../config.yml'
  $settings = Settings.new '../config.yml'

  register Sinatra::MultiRoute

  register Sinatra::R18n
  R18n.default_places { File.expand_path '../locales', __FILE__ }
  set :root, File.dirname(__FILE__)
  R18n::I18n.default = 'es'
  include R18n::Helpers
  I18n.enforce_available_locales = false


  PDFKit.configure do |config|
    config.default_options = { page_size: 'A4',
      margin_top: 5, margin_left: 5, margin_right: 5, margin_bottom: 5,
      footer_left: "#{Utils::local_datetime_format Time.now}", footer_right: '[page] de [toPage]',
      encoding: 'UTF-8', print_media_type: true }
  end

  @@queue = Queue.new
  @@running = true
  def enqueue message
    p "enqueue #{message.name}"
    @@queue << message
  end
  Thread.new do
    while @@running
      task = @@queue.pop
      begin
        print "Performing #{task.class} #{task.name}"
        task.validate
        print "."
        if task.errors.count > 0
          ap task
        end
        print "."
        task.perform
        puts "."
      rescue => e
        ap e.message
        ap e.class
      end
    end
  end

  def current_user
    State.current_user ? State.current_user : User.new
  end

  def current_user_id
    State.current_user.user_id
  end

  def current_location
    State.current_location
  end

  configure :production, :development, :test do
    #rack protection
    set :protection, :origin_whitelist => ['http://www.maquillajetiti.com.ar']

    before do
      # cache_control :no_cache, :no_store, :must_revalidate, :proxy_revalidate
    end

    after do
    end

    require_relative 'models/stdout_logger' if settings.debug_sql

    #slim
    Slim::Engine.set_default_options pretty: true, sort_attrs: false
    set :static, true
    set :public_folder, "#{File.expand_path '../public', __FILE__}"
    set :static_cache_control, [:public, {max_age: 60 * 60 * 24 * 365}]
    views = ['views', 'views/layouts', 'views/pages', 'views/partials', 'views/ajax']
    set :views, views.map{|view| File.expand_path "../#{view}", __FILE__}
    set :template_engine, :slim

  end

  configure :production, :development do
    enable :logging
    disable :raise_errors
    disable :show_exceptions
  end

  configure :production do
  end

  configure :development do
    require 'sinatra/reloader'
    register Sinatra::Reloader
    enable :reload_templates
    also_reload "models/*.rb"
    also_reload "helpers/*.rb"
    also_reload "sinatra/*.rb"
    also_reload "./*.rb"
    Sinatra::Application.reset!
  end

  configure :test do
  end

  not_found do
    slim :not_found, layout: false
  end

  error SecurityError do
    # slim :error, layout: :layout_bare, locals: {error: $!, backtrace: nil, title: "Error de permisos"}
    flash[:error] = $!.message
    redirect to("/")
  end

  error do
    logger.error request.env['sinatra.error']
    ap $@
    logger.error $!.class
    logger.error "Message: #{$!.message}"
    logger.error "Route: #{request.env['sinatra.route']}"
    logger.error "Request path: #{request.env['REQUEST_PATH']}"
    slim :error, layout: :layout_bare, locals: {error: $!, backtrace: $@, title: "Error del servidor"}
  end


  def set_locale
    # session[:locale] = extract_locale_from_accept_language_header || 'es'
    session[:locale] = 'es'
  end

  # def extract_locale_from_accept_language_header
  #   begin
  #     request.env['HTTP_ACCEPT_LANGUAGE'].scan(/^[a-z]{2}/).first
  #   rescue
  #     'es'
  #   end
  # end

  helpers do

    def h(text)
      Rack::Utils.escape_html(text)
    end

    def item_distributors item
      item.distributors.select(:d_name, :distributors__d_id).all.map{ |o| o.to_json [:d_name, :d_id] }
    end
  end

end

