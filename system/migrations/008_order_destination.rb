Sequel.migration do
  change do
    run '
      ALTER TABLE orders ADD o_dst char(12) COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT "UNDEFINED" AFTER o_loc;
    '
    run '
      ALTER TABLE orders ADD KEY `order_destination` (`o_dst`);
    '
  end
end
