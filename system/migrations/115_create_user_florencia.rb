Sequel.migration do
  up do
    run 'UPDATE users set password= "$2a$08$fQuq34hg.LwFml5njPIWH.ME0IhtoM07FIWnLRiC2ysfLKI5WjWee" WHERE username = "florencia";'
  end
end

