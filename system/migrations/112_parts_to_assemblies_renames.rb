Sequel.migration do
  change do
    rename_column :parts_to_assemblies, :part_id, :part_i_id
    rename_column :parts_to_assemblies, :part_prod_id, :part_p_id
    rename_column :parts_to_assemblies, :assembly_id, :assembly_i_id
    rename_column :parts_to_assemblies, :assembly_prod_id, :assembly_p_id
  end
end
