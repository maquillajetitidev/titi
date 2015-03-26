Sequel.migration do
  up do
    set_column_type :materials, :m_name, String, fixed: true, size: 80, null: false
  end

  down do
  end
end
