require_relative 'userAuth'
class User < UserAuth

  def username
    @values[:username].nil? ? "nobody" : @values[:username]
  end

  def empty?
    return user_id.nil? ? true : false
  end

  def current_user_id
    current_user_id = State.current_user.user_id unless State.current_user.nil?
    current_user_id ||= 1 # system
  end

  def current_user_name
    current_username = State.current_user.username unless State.current_user.nil?
    current_username ||= "system"
  end

  def current_location
    current_location =  State.current_location unless State.current_location.nil?
    if current_location.nil?
      current_location = {name: "SYSTEM", translation: ConstantsTranslator.new("SYSTEM").t}
    end
    current_location
  end

  def can_edit_products?
      self.level >= 3
  end

  def can_edit_materials?
      self.level >= 3
  end

end
