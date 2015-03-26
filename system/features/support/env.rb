# IN_BROWSER=true bundle exec cucumber
# RACK_ENV=test bundle exec cucumber

#sniplets
# unless ENV['IN_BROWSER']

require 'sinatra'
require 'sinatra/config_file'
require 'sinatra/r18n'
require "i18n"
config_file '../../../config.yml'


# use Rack::MethodOverride
# require 'encrypted_cookie'
# require "rack/csrf"
# use Rack::Session::EncryptedCookie, secret: settings.cookie_secret, expire_after: settings.session_length
# use Rack::Csrf, raise: true, field: 'csrf', key: 'csrf', header: 'X_CSRF_TOKEN' #, :skip => ['POST:/login']

register Sinatra::R18n
R18n.default_places { File.expand_path '../../locales', __FILE__ }
set :root, File.dirname(__FILE__)
R18n::I18n.default = 'es'
include R18n::Helpers
R18n.set('es', './locales/es.yml')
I18n.enforce_available_locales = false

# require 'rspec'
# require 'rspec/expectations'
require 'capybara'
require 'capybara/cucumber'
require 'capybara/poltergeist'


Before do
  DeferredGarbageCollection.start
end

After do
  DeferredGarbageCollection.reconsider
end

Capybara.app = eval("Rack::Builder.new {( " + File.read(File.dirname(__FILE__) + '/../../config.ru') + "\n )}")


if ENV['IN_BROWSER']
  # On demand: non-headless tests via Selenium/WebDriver
  # To run the scenarios in browser (default: Firefox), use the following command line:
  # IN_BROWSER=true bundle exec cucumber
  # or (to have a pause of 1 second between each step):
  # IN_BROWSER=true PAUSE=1 bundle exec cucumber
  Capybara.default_driver = :selenium
  AfterStep do
    sleep (ENV['PAUSE'] || 0).to_i
  end
else
  # DEFAULT: headless tests with poltergeist/PhantomJS
  Capybara.register_driver :poltergeist do |app|
    Capybara::Poltergeist::Driver.new(
      app,
      window_size: [1280, 1024]#, debug:       true
    )
  end
  Capybara.default_driver    = :poltergeist
  Capybara.javascript_driver = :poltergeist
end


class BackendWorld
  include Capybara::DSL
  # include RSpec::Expectations
  # include RSpec::Matchers
end



World do
  R18n.set R18n.available_locales[0].code
  BackendWorld.new
end


def t
  @i18n = R18n::I18n.new('es', File.expand_path('../../../locales', __FILE__) ) if @i18n.nil?
  @i18n
end

def l input
  @es = R18n.locale('es') if @es.nil?
  @es.localize input
end
