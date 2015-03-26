Sequel.migration do
  up do
    run 'ALTER TABLE credit_notes CHANGE cr_ammount cr_ammount DECIMAL(8.2) NOT NULL'
    run 'UPDATE credit_notes SET cr_ammount = cr_ammount * -1'
    run 'UPDATE credit_notes SET cr_status = "VOID"'
  end

  down do
  end
end


