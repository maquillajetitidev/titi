Sequel.migration do
  up do
    run 'alter table products add parts_cost decimal(6,2) unsigned NOT NULL DEFAULT 0 AFTER buy_cost'
    run 'alter table products add materials_cost decimal(6,2) unsigned NOT NULL DEFAULT 0 AFTER parts_cost'
  end

  down do
  end
end



