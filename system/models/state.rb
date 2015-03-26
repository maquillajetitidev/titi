class State
  class << self
    @current_user = nil
    SYSTEM_LOCATION = {name: "SYSTEM", translation: "Interna"}
    @current_location = nil

    def clear
      @current_user = nil
      @current_location = nil
    end

    def current_user
      @current_user.nil? ? User.new : @current_user
    end
    def current_user= new_user
      @current_user = new_user
    end

    def current_location
      @current_location.nil? ? SYSTEM_LOCATION : @current_location
    end
    def current_location= new_location
      @current_location = new_location
    end

    def current_location_name
      @current_location[:name]
    end

  end
end

