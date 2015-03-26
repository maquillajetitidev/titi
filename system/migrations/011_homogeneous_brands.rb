Sequel.migration do
  change do
    run 'update products set brand = "Maquillaje TITI" where brand = "TITI";'
    run 'update products set brand = "Belladersina" where brand like "Belladersina%";'
    run 'update products set brand = "Varias" where brand = "Varias";'
    run 'update products set brand = "Varias" where brand = "";'
  end
end

