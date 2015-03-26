Sequel.migration do
  up do
    run 'ALTER TABLE distributors CHANGE d_name d_name char(40) DEFAULT NULL'
  end
end
