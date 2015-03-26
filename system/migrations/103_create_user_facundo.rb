Sequel.migration do
  up do
    run 'insert into users (username, user_email, level, is_active, password) VALUES ("facundo", "produccion@maquillajetiti.com.ar", 2, 1, "$2a$08$c7xppK0/kab2YO2MC3o5Bu5EbnUjNHv9O84UoG9AVwmX6yZOj8SXS");'
  end

  down do
  end
end

