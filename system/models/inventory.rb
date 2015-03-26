require_relative 'material.rb'

class Inventory
  attr_reader :location, :needed_materials, :missing_materials, :used_bulks, :errors, :material
  def initialize location
    @location = User.new.current_location[:name]
    @user_id = User.new.current_user_id
    @needed_materials = []
    @missing_materials = []
    @used_bulks = []
    @errors = []
  end

  def material m_id = nil
    @material = Material.new(location: location).get_by_id(m_id, location) unless m_id.nil?
    @material = Material.new(location: location).get_list(location) if m_id.nil?
    if @material.respond_to? :map
      @material = @material.all
      @material.map do |material|
        material.location= @location
      end
    end
    @material
  end

  def can_complete_order? order
    return process_order(order, false)
  end

  def process_order order, must_save=true
    case order.type
      when Order::PACKAGING
        return process_packaging_order(order, must_save)
      when Order::ASSEMBLY
        return process_assembly_order(order, must_save)
    end
  end

  def add_item item, o_id
    message = "#{item[:p_name]} agregado al inventario"
    ActionsLog.new.set(msg: message, u_id: @user_id, l_id: @location, lvl:  ActionsLog::NOTICE, i_id: item.i_id, p_id: item.p_id, o_id: o_id).save
    item.i_loc = @location
    item.change_status Item::READY, o_id
  end



  private



    def process_assembly_order order, must_save=true
      raise TypeError, 'Inexistent order' if order.nil?
      DB.transaction do
        @missing_materials = []
        @used_bulks = []
        process_parts(order, must_save)
        process_materials(order, must_save)

        if must_save
          order.change_status Order::FINISHED
        end
      end
      return @missing_materials.empty? ? true : false
    end


    def process_packaging_order order, must_save=true
      raise TypeError, 'Inexistent order' if order.nil?
      o_id = order.o_id
      DB.transaction do
        @missing_materials = []
        @used_bulks = []
        process_parts(order, must_save)
        process_materials(order, must_save)

        if must_save
          order.items.each do |item|
            message = "Materias primas restadas del inventario. Producto terminado"
            ActionsLog.new.set(msg: message, u_id: @user_id, l_id: @location, lvl:  ActionsLog::NOTICE, i_id: item.i_id, o_id: o_id).save
            add_item(item, o_id)
          end
          order.change_status Order::FINISHED
        end
      end
      return @missing_materials.empty? ? true : false
    end

    def needed_bulks material
      Bulk
        .select(:b_id, :m_id, :b_qty, :b_price, :b_status, :b_loc, :bulks__created_at)
        .select_append(:m_name)
        .filter(b_loc: @location, m_id: material.m_id, b_status: Bulk::IN_USE)
        .join(:materials, [:m_id])
        .order(:b_qty)
        .all
    end

    def get_needed_materials container
      @needed_materials = []
      @needed_materials = container.materials
      aux = []
      @needed_materials.each { |n| aux << Utils::deep_copy(n) }
      aux
    end


    def fill_bulk o_id, must_save
      @needed_materials.each do |material|
        needed_bulks(material).each do |bulk|
          @used_bulks << bulk
          starting_b_qty = bulk[:b_qty].dup
          if bulk.b_qty >= material[:m_qty]
            bulk.b_qty -= material[:m_qty]
            material[:m_qty] = 0
          else
            material[:m_qty] -= bulk.b_qty
            bulk.b_qty = 0
          end
          if must_save
            qty = sprintf("%0.3f", (starting_b_qty - bulk.b_qty).round(3))
            message = "Utilizando #{qty} #{bulk[:m_name]}"
            ActionsLog.new.set(msg: message, u_id: @user_id, l_id: @location, lvl:  ActionsLog::NOTICE, b_id: bulk.b_id, m_id: bulk.m_id, o_id: o_id).save
            bulk.change_status(Bulk::EMPTY, o_id) if bulk.b_qty == 0
            bulk.save validate: false, columns: [:b_qty]
          end
        end
        @errors << R18n.t.inventory.missing_x_units_of_material(material[:m_qty], material.m_name) if material[:m_qty] > 0
        raise R18n::t.production.packaging_order.missing_materials_cant_allocate if must_save and (material[:m_qty] > 0)

        @missing_materials << material if material[:m_qty] > 0
      end
    end

    def process_parts order, must_save
      case order.type
        when Order::PACKAGING
          unless order.parts.empty?
            message = "Esta orden tiene kits cargados. No deberias cargarlos por aca. Si imputas la orden vas a generar un error de stock. (las partes de los kits no se van a restar, pero si los materiales)"
            @errors << message
            ActionsLog.new.set(msg: message, u_id: @user_id, l_id: @location, lvl:  ActionsLog::ERROR, o_id: order.o_id).save
          end
      when Order::ASSEMBLY
        product = order.get_assembly
        assembly_meta = order.get_assembly_meta
        if must_save
          items = order.items
          items.each do |part|
            if part.i_status == Item::IN_ASSEMBLY
              part.void! "Este item ahora forma parte del kit \"#{product.p_name}\""
              PartsToAssemblies.insert(pta_o_id: assembly_meta.o_id, part_i_id: part.i_id, part_p_id: part.p_id, assembly_i_id: assembly_meta.i_id, assembly_p_id: assembly_meta.p_id)
            end
          end
        end
      end
    end


    def process_materials order, must_save
      case order.type
        when Order::PACKAGING
          @needed_materials = get_needed_materials order
        when Order::ASSEMBLY
          @needed_materials = get_needed_materials order.get_assembly
      end
      fill_bulk order.o_id, must_save
    end


end
