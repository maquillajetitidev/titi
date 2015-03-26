class Location
  UNDEFINED="UNDEFINED"
  W1="WAREHOUSE_1"
  W2="WAREHOUSE_2"
  S1="STORE_1"
  S2="STORE_2"
  SYS="SYSTEM"
  ER="EN_ROUTE"
  VOID="VOID"
  GLOBAL="GLOBAL"

  WAREHOUSES = [W1, W2]
  ENABLED_WAREHOUSES = WAREHOUSES
  STORES = [S1, S2]
  ENABLED_STORES = [S1]
  LEVEL = {S1 => 1, S2 => 2, W1 => 2, W2 => 2}

  def warehouses
    translated_list ENABLED_WAREHOUSES
  end
  def stores
    translated_list ENABLED_STORES
  end
  def store_1
    translated_list [S1]
  end

  def level_1
    translated_list LEVEL_1
  end
  def level_2
    translated_list LEVEL_2
  end
  def level_2
    translated_list LEVEL_3
  end


  def stores
    translated_list ENABLED_STORES
  end


  def valid? location
    (ENABLED_WAREHOUSES + ENABLED_STORES + [ER]).include? location
  end

  def store? location
    ENABLED_STORES.include? location
  end

  def warehouse? location
    ENABLED_WAREHOUSES.include? location
  end

  def get name
    if name.nil?
      current = {name: "", translation: ""}
    else
      current = {name: name, translation: ConstantsTranslator.new(name).t, level: LEVEL[name]}
    end
    current
  end

  private
  def translated_list items
    list = []
    items.each do |name|
      current = get name
      list << current
    end
    list
  end

end
