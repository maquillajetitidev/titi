Sequel.migration do
  up do
    run 'ALTER TABLE users CHANGE level level INT(1) UNSIGNED NOT NULL DEFAULT 0'
  end
end
