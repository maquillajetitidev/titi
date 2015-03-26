Sequel.migration do
  change do
    rename_column :book_records, :id, :r_id
  end
end