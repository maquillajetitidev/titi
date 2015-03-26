Sequel.migration do
  change do
    run 'ALTER TABLE products change `brand` `br_name` char(20) COLLATE utf8mb4_unicode_ci NOT NULL'
  end
end
