Sequel.migration do
  up do
    run 'update users set password = "$2a$08$fZFaeOudXR3/qV6jrJbRhea4JcSTU1IvpUbXdZNIJDAqPmHH0/.ky" where username = "aburone";'
  end

  down do
  end
end
