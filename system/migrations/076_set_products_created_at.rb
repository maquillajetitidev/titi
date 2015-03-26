Sequel.migration do
  up do
    run '
      UPDATE products, sells
      SET products.created_at = sells.sell_datetime
      WHERE products.p_id = sells.art_id AND products.created_at IS NULL;
    '

    run '
      UPDATE products, line_items, items
      SET products.created_at = line_items.created_at
      WHERE products.p_id = items.p_id AND line_items.i_id = items.i_id AND products.created_at IS NULL;
    '

    run '
      UPDATE products, actions_log
      SET products.created_at = actions_log.at
      WHERE products.p_id = actions_log.p_id AND products.created_at IS NULL;
    '

    run '
      UPDATE products SET price_updated_at = created_at WHERE price_updated_at IS NULL;
    '
  end

  down do
  end
end
