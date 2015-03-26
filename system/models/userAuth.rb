class UserAuth < Sequel::Model(:users)
  require "bcrypt"
  BCrypt::Engine.cost = 8

  def get_by_id user_id
    User[user_id.to_i]
  end

  def get_user username
    User.where(Sequel.like(:username, username)).first # this is in order to be unicode aware
  end

  def password=(new_password)
    self[:password] = BCrypt::Password.create(new_password)
  end

  def valid? username, password
    user = get_user username
    if user && user.is_active && (valid_pass? user, password )
      return user
    else
      return false
    end
  end

  private
    def valid_pass? user, password
      stored = BCrypt::Password.new( user[:password] )
      stored == password
    end

end
