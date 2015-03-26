Sequel.migration do
  change do
    run '
      INSERT INTO parts_to_assemblies (pta_o_id, part_i_id, part_p_id, assembly_i_id, assembly_p_id)
      SELECT line_items.o_id
        , line_items.i_id
        , items.p_id
        , assembly_orders_to_products.i_id
        , products.p_id
        from line_items join items using (i_id) join assembly_orders_to_products using(o_id) join products on products.p_id = assembly_orders_to_products.p_id;
    '
  end
end
