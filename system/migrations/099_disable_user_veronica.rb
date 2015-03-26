Sequel.migration do
  up do
    run 'update users set is_active = 0 where username = "veronica";'
  end

  down do
  end
end
