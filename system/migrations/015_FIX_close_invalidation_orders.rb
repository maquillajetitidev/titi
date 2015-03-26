Sequel.migration do
  change do
    run 'UPDATE orders SET o_status = "FINISHED" WHERE type = "INVALIDATION"'
  end
end
