Sequel.migration do
  change do
    rename_column :parts_to_assemblies, :o_id, :pta_o_id
  end
end

