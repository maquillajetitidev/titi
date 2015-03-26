Sequel.migration do
  up do
    run 'update products set price_pro = round(price*10 *0.95)/10;'
  end

  down do
  end
end
