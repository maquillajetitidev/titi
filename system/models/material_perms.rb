class Material < Sequel::Model(:materials)

  def owned_by? actor
    return actor.is_a?(User) && actor.user_id == 1 ? true : false # 1 is system
  end

  def self.can_list?(actor)
    true
  end

  def can_view?(actor)
    actor.is_a?(User)
  end

  def can_be_updated_by?(actor)
    actor.is_a?(User) && (actor.level >= 3 || self.owned_by?(actor))
  end

  def update_from_hash(hash_values)
    raise ArgumentError, t.errors.nil_params if hash_values.nil?
    raise SecurityError, "#{State.current_user.username}: no tenes permisos para actualizar materiales" unless self.can_be_updated_by? State.current_user


    wanted_keys = [ :m_name, :m_notes, :c_id, :SKU ]
    hash_values.select { |key, value| self[key.to_sym]=value if wanted_keys.include? key.to_sym unless value.nil?}

    numerical_keys = [ :m_ideal_stock, :m_price ]
    hash_values.select do |key, value|
      if numerical_keys.include? key.to_sym
        unless value.nil? or (value.class == String and value.length == 0)
          if Utils::is_numeric? value.to_s.gsub(',', '.')
            self[key.to_sym] = Utils::as_number value
          end
        end
      end
    end

    validate
    self
  end

end
