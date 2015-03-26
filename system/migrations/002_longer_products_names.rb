Sequel.migration do
  up do
    run 'alter table items change p_name p_name varchar(200) COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT "INVALID";'
    run 'alter table products change p_name p_name varchar(200) COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT "INVALID";'
  end
end
