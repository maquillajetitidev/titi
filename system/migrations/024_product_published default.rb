Sequel.migration do
  up do
    set_column_default :products, :published, 0
    set_column_default :products, :published_price, 0
  end

  down do
  end
end
