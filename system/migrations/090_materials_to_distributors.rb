Sequel.migration do
  up do
    run '
      CREATE TABLE materials_to_distributors (
        m_id int(5) UNSIGNED NOT NULL,
        d_id int(5) UNSIGNED NOT NULL,
        created_at datetime DEFAULT NULL,
        UNIQUE KEY (m_id, d_id),
        UNIQUE KEY (d_id, m_id)
      );
    '

    run '
      CREATE TRIGGER mtd_insert BEFORE INSERT ON `materials_to_distributors`
        FOR EACH ROW BEGIN
          SET NEW.created_at = IFNULL(NEW.created_at, NOW());
        END
    '

  end

  down do
    drop_table :materials_to_distributors
  end
end



