Sequel.migration do
  up do
    run "ALTER TABLE materials ADD m_price decimal(12,6) unsigned NOT NULL DEFAULT '0.000000'"
  end

  down do
    drop_column :materials, :m_price
  end
end


