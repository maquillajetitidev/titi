require_relative 'prerequisites'

class InitTest < Test::Unit::TestCase
  def self.startup
    p "start"
    @@only_once = "only_once, can make several with different names"
  end

  def setup
    @valid_item = Item.new
    @valid_item.i_id = (rand * 1000).to_s[0..11]
    @valid_item.p_id = 1234
    @valid_item.p_name = "un nombre"
    @valid_item.i_status = Item::ASSIGNED
    @valid_item.i_loc = Location::W1
    @valid_item.i_price = 10
    @valid_item.i_price_pro = 8
    @valid_item.created_at = Time.now
  end


  # uncomment for multiple setups
  setup
  def setup_two
    p "s2"
  end

  def test_needing_startup_n_teardown
    p "needy test"
    assert true
    notify("Debug")
    p " debug statement "
    notify("/Debug")
    # pend()
    # omit("pete")
    # omit_if(cond, "msg")
    # omit_unless(cond, "msg")
  end

  def teardown
    p "t1"
  end

  teardown
  def teardown_two
    p "t2"
  end

  def self.shutdown
    p "shut"
  end
end
