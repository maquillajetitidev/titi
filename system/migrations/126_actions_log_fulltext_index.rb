
Sequel.migration do
  up do
    run "CREATE FULLTEXT INDEX actions_log_msg_index ON actions_log(msg);"
  end
end


