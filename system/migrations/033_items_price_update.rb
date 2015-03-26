Sequel.migration do
  up do
    run 'UPDATE items
          JOIN products using(p_id)
          SET items.i_price = products.price
          WHERE i_status IN ( "ASSIGNED", "MUST_VERIFY", "VERIFIED", "READY" )
        '
  end

  down do
  end
end



