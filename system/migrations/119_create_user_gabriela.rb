Sequel.migration do
  up do
    run 'insert into users (username, user_email, level, is_active, password) VALUES ("gabriela", "gabriela@maquillajetiti.com.ar", 2, 1, "$2a$08$blwezt0MlTJBBpU3V3fL1eBt9jitqOIBQiLb4ubk.txlE34jzXYVC");'
  end
end

