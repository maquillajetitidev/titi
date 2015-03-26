require "ostruct"

class Settings

  def initialize file
    @settings = OpenStruct.new YAML::load( File.read( file ) )
    @settings = OpenStruct.new @settings.test if Sinatra::Base.test?
    @settings = OpenStruct.new @settings.development if Sinatra::Base.development?
    @settings = OpenStruct.new @settings.production if Sinatra::Base.production?
  end

  def method_missing(method, *args, &block)
    ret = eval( "@settings.#{method}" )
    raise "No tengo ninguna configuracion llamada #{method}" if ret.nil?
    ret
  end  

  def respond_to?(method, include_private = false)
    eval( "@settings.#{method}" ) ? true : false
  end
end
