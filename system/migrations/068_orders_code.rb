Sequel.migration do
  up do
    run '
    ALTER TABLE orders ADD `o_code` char(6) NULL AFTER o_id;
    '
    run '
    ALTER TABLE orders ADD CONSTRAINT order_code UNIQUE (o_code);
    '

    run '
    DROP TRIGGER   o_init;
    '

    run '
        CREATE TRIGGER o_init BEFORE UPDATE ON `orders`
          FOR EACH ROW BEGIN
            SET NEW.created_at = IFNULL(NEW.created_at, NOW());
            IF( NEW.type = "SALE" OR NEW.type = "RETURN" OR NEW.type = "CREDIT_NOTE" ) THEN
              SET NEW.o_code = left( uuid(), 6);
            ELSE
              SET NEW.o_code = NULL;
            END IF;
          END
    '

    run '
    UPDATE orders SET o_id = o_id;
    '

    run '
    DROP TRIGGER   o_init;
    '

    run '
        CREATE TRIGGER o_init BEFORE INSERT ON `orders`
          FOR EACH ROW BEGIN
            SET NEW.created_at = IFNULL(NEW.created_at, NOW());
            IF( NEW.type = "SALE" OR NEW.type = "RETURN" OR NEW.type = "CREDIT_NOTE" ) THEN
              SET NEW.o_code = left( uuid(), 6);
            ELSE
              SET NEW.o_code = NULL;
            END IF;
          END
    '
  end

  down do
    run '
    DROP TRIGGER o_init;
    '
    run '
    CREATE TRIGGER o_init BEFORE INSERT ON `orders`
    FOR EACH ROW SET
    NEW.created_at = IFNULL(NEW.created_at, NOW());
    '
    run '
    ALTER TABLE orders DROP INDEX order_code;
    '
    run '
    ALTER TABLE orders DROP o_code;
    '
  end
end





