Sequel.migration do
  up do
    rename_column :products, :is_published, :published
    rename_column :products, :price_is_published, :published_price
    rename_column :products, :can_be_sold, :archived
    run 'UPDATE products SET archived = case when archived then 0 else 1 end'
  end

  down do
    rename_column :products, :published, :is_published
    rename_column :products, :published_price, :price_is_published
    rename_column :products, :archived, :can_be_sold
    run 'UPDATE products SET archived = case when archived then 0 else 1 end'
  end
end
