# Sequel
Sequel::Model.raise_on_save_failure = TRUE
Sequel::Model.plugin :defaults_setter

  # Sequel::Model.plugin :association_pks
  # Material.plugin :association_pks
  #   mat = Material[38]
  #   ap mat.bulk_pks


  # Sequel::Model.plugin :tactical_eager_loading
  #   def test_eager_load
  #     Material.filter{m_id<100}.all do |a|
  #       a.bulks
  #     end
  #   end


  # Sequel::Model.plugin :timestamps
  # # Timestamp Album instances, with custom column names
  # Album.plugin :timestamps, :create=>:created_on, :update=>:updated_on


Sequel::Model.plugin :dataset_associations
Sequel::Model.plugin :nested_attributes
Sequel::Model.plugin :skip_create_refresh # necesario por el trigger que regenera el id
  # Sequel::Model.plugin :update_primary_key
  # Bulk.plugin :update_primary_key

Sequel::Model.plugin :string_stripper
Sequel::Model.plugin :validation_helpers


configure :production do
  Sequel::Model.plugin :prepared_statements
  Sequel::Model.plugin :prepared_statements_associations
end

DB = Sequel.mysql2('maquillajetiti', encoding: 'utf8', compress: true , host: settings.db_host, user: settings.db_user, password: settings.db_pass)

DB.extension :date_arithmetic
