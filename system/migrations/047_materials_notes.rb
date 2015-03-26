Sequel.migration do
  up do
    run "ALTER TABLE materials ADD `m_notes` text NOT NULL after `m_name`"
  end

  down do
    drop_column :materials, :m_notes
  end
end

