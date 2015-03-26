
Sequel.migration do
  up do
    run "alter table actions_log CHANGE msg msg varchar(512) COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT '';"
  end
end

