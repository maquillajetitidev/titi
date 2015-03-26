# coding: utf-8
require 'sequel'

class Distributor < Sequel::Model(:distributors)
  many_to_many :products , left_key: :d_id, right_key: :p_id, join_table: :products_to_distributors
  many_to_many :materials , left_key: :d_id, right_key: :m_id, join_table: :materials_to_distributors

  ATTRIBUTES = [:d_id, :d_name, :d_has_pricelist, :d_notes, :created_at, :updated_at]
  # same as ATTRIBUTES but with the neccesary table references for get_ functions
  COLUMNS = [:distributors__d_id, :d_name, :d_has_pricelist, :d_notes, :distributors__created_at, :distributors__updated_at]

  def to_json attributes = Distributor::ATTRIBUTES
      hash = {}
      attributes.each do |var|
          hash[var] = method(var).call
      end
      hash.to_json
  end
  def from_json! string
      JSON.load(string).each do |var, val|
          self.instance_variable_set var, val
      end
  end

  def get d_id
    return Distributor.new unless d_id.to_i > 0
    distributor = Distributor.select_group(*Distributor::COLUMNS).where(d_id: d_id.to_i).first
    return Distributor.new if distributor.nil?
    distributor
  end

  def empty?
    return @values[:d_id].nil? ? true : false
  end

  def update_from_hash(hash_values)
    wanted_keys = [ :d_name, :d_notes ]
    hash_values.select { |key, value| self[key.to_sym]=value if wanted_keys.include? key.to_sym unless value.nil?}

    checkbox_keys = [:d_has_pricelist]
    checkbox_keys.each { |key| self[key.to_sym] = hash_values[key].nil? ? 0 : 1 }

    validate
    self
  end

  def validate
    super
    errors.add(:Nombre, R18n.t.errors.presence) if !d_name || d_name.empty?
  end

end

class ProductDistributor < Sequel::Model(:products_to_distributors)
  ATTRIBUTES = [:ptd_id, :p_id, :d_id, :relation_created_at]
  # same as ATTRIBUTES but with the neccesary table references for get_ functions
  COLUMNS = [:products_to_distributors__ptd_id, :products_to_distributors__p_id, :products_to_distributors__d_id, :relation_created_at]
end

class MaterialDistributor < Sequel::Model(:materials_to_distributors)
  ATTRIBUTES = [:mtd_id, :m_id, :d_id, :relation_created_at]
  # same as ATTRIBUTES but with the neccesary table references for get_ functions
  COLUMNS = [:materials_to_distributors__mtd_id, :materials_to_distributors__m_id, :materials_to_distributors__d_id, :relation_created_at]
end
