Sequel.migration do
  up do
    run 'ALTER TABLE credit_notes CHANGE cr_ammount cr_ammount decimal(10, 2)'
  end

  down do
  end
end

