require "singleton"
  require 'encrypted_cookie'
  require "rack/csrf"
  use Rack::Session::EncryptedCookie, secret: 'sdfdsfgdfsgdfsg', expire_after: 3600

  class Session
  include Singleton

  def initialize
    @session = session
  end

  attr_accessor :session
end
