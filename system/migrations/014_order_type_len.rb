Sequel.migration do
  change do
    set_column_type :orders, :type, String, fixed: true, size: 12, null: false, index: true
  end
end