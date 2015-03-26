# coding: utf-8
require_relative 'prerequisites'
class UserTest < Test::Unit::TestCase

  def setup
    @active_username = "aburone"
    @active_password = "1234"
    @active_hash = "$2a$04$Sa0R4lz7t3RJ/z2K5A2FMe7kB/g/l2AQcOvwBUHrq3Mp5Yh6YHOtu"

    @inactive_username = "veronica"
    @inactive_password = "qwe123"
    @inactive_hash = "$2a$04$ql61.LzmofNn5plOO4VlouoSwopoHylx2pl03APsTz2Hg7YmWg03e"
  end

  def how_to
    # https://github.com/codahale/bcrypt-ruby

    my_password = BCrypt::Password.create("my password")
    #=> "$2a$10$vI8aWBnW3fID.ZQ4/zo1G.q1lRps.9cGLcZEiGDMVr5yUP1KUOYTa"
    my_password.version              #=> "2a"
    my_password.cost                 #=> 10
    my_password == "my password"     #=> true
    my_password == "not my password" #=> false

    my_password = BCrypt::Password.new("$2a$10$l1MLSp6gZvxX263Z9cxZnOHuaB5XdwaNtmL3819w/U/mov5uRKysu")
    my_password == "qwe123"     #=> true
    my_password == "not my password" #=> false
  end

  def test_should_diferentiate_unicode_usernames
    u = User.new.get_user "aburone"
    u2 = User.new.get_user "áburone"
    assert_not_equal( u, u2)
  end

  def test_should_validate_good_password
    DB.transaction(rollback: :always, isolation: :uncommitted) do
      user = User.new.get_user( @active_username )
      user[:password] = @active_hash
      user.save
      assert_equal User.new.valid?( @active_username, @active_password ), user
    end
  end

  def test_should_reject_inactive_user
    DB.transaction(rollback: :always, isolation: :uncommitted) do
      user = User.new.get_user( @inactive_username )
      user[:password] = @inactive_hash
      user.save
      assert_false User.new.valid? @inactive_username, @inactive_password
  end
    end

  def test_should_reject_password
    DB.transaction(rollback: :always, isolation: :uncommitted) do
      user = User.new.get_user( @active_username )
      user[:password] = @inactive_hash
      user.save
      assert_false User.new.valid?( @active_username, "INVALID" )
    end
  end

  def create_passwords
    pass =  BCrypt::Password.create("qwe123", {cost: 2})
    ap pass
  end
end
