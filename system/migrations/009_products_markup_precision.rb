Sequel.migration do
  change do
    run '
      alter table products change markup markup  decimal(12,3) unsigned NOT NULL DEFAULT 0;
    '
  end
end

