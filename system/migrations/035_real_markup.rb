Sequel.migration do
  up do
    run "
      UPDATE products SET ideal_markup = real_markup
    "

  end

  down do
  end
end




