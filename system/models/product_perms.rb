class Product < Sequel::Model

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
    raise SecurityError, "#{State.current_user.username}: no tenes permisos para actualizar productos" unless self.can_be_updated_by? State.current_user

    numerical_keys = [ :direct_ideal_stock, :indirect_ideal_stock, :stock_store_1, :stock_store_2, :stock_warehouse_1, :stock_warehouse_2, :stock_deviation, :buy_cost, :materials_cost, :parts_cost, :sale_cost, :ideal_markup, :real_markup, :exact_price, :price, :price_pro]
    hash_values.select do |key, value|
      if numerical_keys.include? key.to_sym
        unless value.nil? or (value.class == String and value.length == 0)
          if Utils::is_numeric? value.to_s.gsub(',', '.')
            self[key.to_sym] = Utils::as_number value
          end
        end
      end
    end
    cast

    alpha_keys = [ :c_id, :p_short_name, :packaging, :size, :color, :sku, :public_sku, :description, :notes, :img, :img_extra ]
    hash_values.select { |key, value| eval("self.#{key}=value.to_s") if alpha_keys.include? key.to_sym unless value.nil?}

    checkbox_keys = [:published_price, :published]
    checkbox_keys.each { |key| self[key.to_sym] = hash_values[key].nil? ? 0 : 1 }

    true_false_keys = [:tercerized]
    true_false_keys.each { |key| self[key.to_sym] = hash_values[key] == "true" ? 1 : 0 }

    set_life_phase hash_values[:life_phase]
    set_sale_mode hash_values[:sale_mode]

    unless hash_values[:brand].nil?
      brand_json = JSON.parse(hash_values[:brand])
      brand_keys = [ :br_id, :br_name ]
      brand_keys.select { |key, value| self[key.to_sym]=brand_json[key.to_s] unless brand_json[key.to_s].nil?}
    end

    self[:p_name] = ""
    [self[:p_short_name], self[:br_name], self[:packaging], self[:size], self[:color], self[:public_sku] ].map  { |part| self[:p_name] += " " + part unless part.nil?}
    cast
    self
  end

end
