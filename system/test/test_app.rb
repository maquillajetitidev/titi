require_relative 'prerequisites'
require_relative '../app_controller.rb'
require_relative '../backend.rb'

class AppTest < Test::Unit::TestCase
  include Rack::Test::Methods
  def app
    Backend
  end

  def test_should_try_to_authenticate
    get '/', {}, 'rack.session' => get_sess
    assert_match(/Administración/, last_response.body, "Wrong place")
  end

  def test_materials_id_invalid
    get '/materials/invalid', {}, 'rack.session' => get_sess
    assert_equal 302, last_response.status, "Error in get '/materials/invalid'"
  end


  def get_sess
    {:locale=>"es",
     :username=>"aburone",
     :user_real_name=>"",
     :user_id=>2,
     :current_location=>{:name=>"WAREHOUSE_1", :translation=>"Deposito 1", :level=>2}}
  end

end
