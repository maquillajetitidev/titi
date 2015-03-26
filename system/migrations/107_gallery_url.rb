Sequel.migration do
  up do
    run 'update gallery set  e_url = concat("http://", e_url) where e_url<>"" and e_url not like "http%";'
  end

  down do
  end
end
