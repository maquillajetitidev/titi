# coding: utf-8
require 'sequel'

class ProductsPart < Sequel::Model
end

class PartsToAssemblies < Sequel::Model
  class << self

  def get_items_in_assemblies
    PartsToAssemblies
      .select_group(:part_i_id, :part_p_id, :part__p_name___part_p_name, :assembly_i_id, :assembly_p_id, :assy__p_name___assembly_p_name, :assy__i_loc___assembly_i_loc, :assy__i_status___assembly_i_status)
      .join(:items___part, parts_to_assemblies__part_i_id: :part__i_id)
      .join(:items___assy, parts_to_assemblies__assembly_i_id: :assy__i_id)
      .where(assy__i_status: ["READY", "MUST_VERIFY"])
    end

    def get_items_via_assembly_part_p_id part_p_id
      get_items_in_assemblies
        .where(part_p_id: part_p_id)
    end

    def get_items_via_assembly_part_p_id_and_location part_p_id, i_loc
      get_items_via_assembly_part_p_id(part_p_id)
        .where(assy__i_status: "READY")
        .exclude(assy__i_status: "MUST_VERIFY")
        .where(assy__i_loc: i_loc)
    end


    def get_items_via_assembly_part_p_id_en_route_to_location part_p_id, i_loc
      get_items_via_assembly_part_p_id(part_p_id)
        .where(assy__i_status: "MUST_VERIFY")
        .exclude(assy__i_status: "READY")
        .where(assy__i_loc: i_loc)
    end

  end


end
