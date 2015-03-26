Sequel.migration do
  change do
    set_column_default :book_records, :o_id, 0

  end
end