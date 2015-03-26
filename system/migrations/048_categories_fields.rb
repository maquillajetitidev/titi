Sequel.migration do
  up do
    run "ALTER TABLE categories CHANGE `c_id` `c_id` int(5) unsigned NOT NULL AUTO_INCREMENT"
    run "ALTER TABLE categories CHANGE `c_name` `c_name` char(80) NOT NULL DEFAULT 'INVALID'"
    run "ALTER TABLE categories CHANGE `description` `description` text NOT NULL"
    run "ALTER TABLE categories CHANGE `is_published` `published` tinyint(1) unsigned NOT NULL DEFAULT '0'"
    run "ALTER TABLE categories CHANGE `img` `img` char(100) NOT NULL DEFAULT ''"
  end

  down do
  end
end


    