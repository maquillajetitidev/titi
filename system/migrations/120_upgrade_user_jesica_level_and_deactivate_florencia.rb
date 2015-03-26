Sequel.migration do
  up do
    run 'UPDATE users SET level=4 WHERE username = "jesica";'
    run 'UPDATE users SET is_active=0 WHERE username = "florencia";'
  end
end

