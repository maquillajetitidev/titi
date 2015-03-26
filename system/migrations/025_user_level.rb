Sequel.migration do
  up do
    # drop_column :users, :level_2
    # drop_column :users, :level_3
    run 'ALTER TABLE users CHANGE level_1 level INT(1) UNSIGNED NOT NULL DEFAULT 1 AFTER password'
    set_column_type :users, :user_email, String, fixed: true, size: 40, null: false

    run 'UPDATE users SET level=1 WHERE username="cristina"'
    run 'UPDATE users SET level=2 WHERE username IN ("veronica", "haydee")'
    run 'UPDATE users SET level=3 WHERE username IN ("juan")'
    run 'UPDATE users SET level=4 WHERE username IN ("aburone")'
    run 'UPDATE users SET level=5 WHERE username IN ("system")'
  end

  down do
  end
end
