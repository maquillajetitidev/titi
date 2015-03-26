Sequel.migration do
  up do
    run 'update users set password = "$2a$08$.f2RRnt2jiR8vPhSc15xk.pxisTz1W6Yw.aCb2OXl4gvqX1cDVLsq" where username = "haydee";'
    run 'update users set password = "$2a$08$Pm9Qa.Rvu8wJ95djBUDtKeGYRKXBuRYKFCoQbIQyEzkSjTbMWdn4C" where username = "juan";'
    run 'update users set password = "$2a$08$nxGq6R2uxexEPxqkQc/Grus6emBQ2Fyj4YdpYxNfJPTsINc5kw/HK" where username = "aburone";'
    run 'insert into users (username, user_email, level, is_active, password) VALUES ("jesica", "jesica@maquillajetiti.com.ar", 2, 1, "$2a$08$RtOcrf9F.nrLW2bc6HhxaOCt/h5scSe5RL2drWHyZCIUDVDrVCCGW");'
    run 'update users set is_active = 0 where username = "veronica";'
    drop_column :users, :level_2
    drop_column :users, :level_3
  end

  down do
  end
end
