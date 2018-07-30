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

  def test_create_passwords
    pass =  BCrypt::Password.create("anibal99", {cost: 2})
    print "pass:"
    print pass
    print "\n"
  end
end
