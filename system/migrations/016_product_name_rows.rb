Sequel.migration do
  up do
    set_column_type :products, :p_name, String, fixed: true, size: 191, null: false, index: true, default: ""
    set_column_type :products, :packaging, String, fixed: true, size: 50, null: false, default: "INVALID"

    run "ALTER TABLE products ADD `p_short_name` char(100) NOT NULL default 'NEW' after p_name"
    run "ALTER TABLE products ADD `size` char(10) NOT NULL default ''  after packaging"
    run "ALTER TABLE products ADD `color` char(35) NOT NULL default ''  after size"
    run "ALTER TABLE products ADD `sku` char(60) NOT NULL  after color"
  end

# 60
# Maquillaje fluido humectante ultrabalanced & perfect skin
# 20
# Maquillaje TITI
# 40
# Kit de 10 pastillas mas polvo volatil
# 10
# Mediano
# 40
# Fluo Naranja Rosa Verde y Amarillo)
# 60
# Nro 10 Lengua de Gato


# name 60
# brand 20
# presentation 40
# size 10
# color 40
# sku 60

# 230


  down do
    drop_column :products, :p_short_name
    drop_column :products, :size
    drop_column :products, :color
    drop_column :products, :sku
  end
end
