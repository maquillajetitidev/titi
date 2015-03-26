Sequel.migration do
  up do
    run "ALTER TABLE materials add `m_ideal_stock` decimal(10,2) unsigned default 0 NOT NULL"
  end

  down do
    drop_column :materials, :m_ideal_stock 
  end
end


    