Sequel.migration do
  up do
    run "ALTER TABLE categories CHANGE `published` `c_published` tinyint(1) unsigned NOT NULL DEFAULT '0'"
  end

  down do
  end
end


    