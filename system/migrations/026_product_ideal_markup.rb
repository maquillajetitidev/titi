Sequel.migration do
  up do
    run 'UPDATE products SET ideal_markup = real_markup where ideal_markup = 0 and real_markup > 0'
  end

  down do
  end
end
