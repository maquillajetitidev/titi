Sequel.migration do
  up do
    run 'ALTER TABLE products CHANGE img img char(100) NOT NULL default "";'
    run 'ALTER TABLE products CHANGE img_extra img_extra char(100) NOT NULL default "";'
  end

  down do
  end
end

