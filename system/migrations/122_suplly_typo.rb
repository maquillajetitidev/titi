Sequel.migration do
  change do
    rename_column :supplies, :wharehouses_whole, :warehouses_whole
    rename_column :supplies, :wharehouses_whole_en_route, :warehouses_whole_en_route
    rename_column :supplies, :wharehouses_whole_future, :warehouses_whole_future
    rename_column :supplies, :wharehouses_whole_ideal, :warehouses_whole_ideal
    rename_column :supplies, :wharehouses_whole_deviation, :warehouses_whole_deviation
    rename_column :supplies, :wharehouses_part, :warehouses_part
    rename_column :supplies, :wharehouses_part_en_route, :warehouses_part_en_route
    rename_column :supplies, :wharehouses_part_future, :warehouses_part_future
    rename_column :supplies, :wharehouses_part_ideal, :warehouses_part_ideal
    rename_column :supplies, :wharehouses_part_deviation, :warehouses_part_deviation
    rename_column :supplies, :wharehouses, :warehouses
    rename_column :supplies, :wharehouses_en_route, :warehouses_en_route
    rename_column :supplies, :wharehouses_future, :warehouses_future
    rename_column :supplies, :wharehouses_ideal, :warehouses_ideal
    rename_column :supplies, :wharehouses_deviation, :warehouses_deviation
  end
end

