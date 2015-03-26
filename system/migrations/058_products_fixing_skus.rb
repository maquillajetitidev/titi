Sequel.migration do
  change do
    run 'UPDATE products SET sku = trim(replace(sku, "Art.", "")) where sku <> "";'
  end
end


