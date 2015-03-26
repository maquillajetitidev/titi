Sequel.migration do
  up do
    run "ALTER TABLE materials MODIFY COLUMN m_notes TEXT NULL"
  end

  down do
    drop_column :materials, :m_notes
  end
end


