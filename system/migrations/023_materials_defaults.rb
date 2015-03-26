Sequel.migration do
  up do
    set_column_default :materials, :m_name, "! NUEVO MATERIAL"
  end

  down do
  end
end
