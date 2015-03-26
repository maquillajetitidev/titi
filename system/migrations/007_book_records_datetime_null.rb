Sequel.migration do
  change do
    alter_table(:book_records) do
      set_column_allow_null :created_at
    end
  end
end