Sequel.migration do
  up do
    run 'insert into users (username, user_email, level, is_active, password) VALUES ("florencia", "florencia@maquillajetiti.com.ar", 2, 1, "$2a$08$RC150khg2I5LW.vJ2is3W.WdH/1bzROT5hRrA5kfCc9NQS9I7XqHu");'
  end

  down do
  end
end

