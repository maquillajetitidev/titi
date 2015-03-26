Sequel.migration do
  change do
    run 'UPDATE products SET sku = NULL where sku = "";'
  end
end


