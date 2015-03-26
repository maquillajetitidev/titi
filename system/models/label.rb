require_relative 'item'
class Label < Item
  def get_unprinted
    Item.filter(i_status: Item::NEW).order(:created_at)
  end

  def get_printed
    Label.filter(i_status: Item::PRINTED).order(:created_at)
  end

  def get_printed_by_id i_id, o_id
    i_id = i_id.to_s.strip
    label = get_printed.filter(i_id: i_id).first
    if label.nil?
      label = Label[i_id]
      if label.nil?
        message = "No tengo ninguna etiqueta con el id #{i_id}"
        errors.add("Error general", message)
        return self
      end
      if label.i_status == Item::ASSIGNED
        message = "Este item (#{label.i_id}) ya esta asignado a #{label.p_name}"
        errors.add("Error general", message)
        return self
      end
      if label.i_status == Item::VOID
        message = "Esta etiqueta fue anulada (#{label.i_id}). Tenias que haberla destruido"
        errors.add("Error general", message)
        return self
      end
      if label.i_status == Item::NEW
        message = "Esta etiqueta aun no fue impresa... (#{label.i_id})."
        errors.add("Error general", message)
        return self
      end
      if label.i_status != Item::PRINTED
        message = "Esta etiqueta esta en estado \"#{ConstantsTranslator.new(label.i_status).t}\". Solo podes utilizar etiquetas en estado \"#{ConstantsTranslator.new(Item::PRINTED).t}\"."
        errors.add("Error general", message)
        return self
      end

      if errors.count == 0
        item_o_id = Item.select(:o_id).filter(i_id: i_id).join(:line_items, [:i_id]).first[:o_id]

        if item_o_id  == o_id
          message = "Este item ya esta en la orden actual"
          errors.add("Error leve", message)
        else
          message = "No podes utilizar el item #{label.i_id} en la orden actual por que esta en la orden #{item_o_id}"
          errors.add("Error general", message)
        end
      end
      return self
    else
      return label
    end
  end

  def get_as_csv
    labels = get_unprinted.all
    DB.transaction do
      labels.each { |label| label.change_status(Item::PRINTED, nil) }
    end
    out = ""
    labels.each do |label|
      out += sprintf "\"#{label.i_id}\",\"Vto: #{(label.created_at+2.years).strftime("%b %Y")}\"\n"
    end
    out
  end

  def create qty
    qty.to_i.times do
      DB.transaction do
        Item.insert()
        last_i_id = DB.fetch( "SELECT @last_i_id" ).first[:@last_i_id]
        current_user_id =  User.new.current_user_id
        current_location = User.new.current_location[:name]
        message = R18n.t.label.created
        ActionsLog.new.set(msg: message, u_id: current_user_id, l_id: current_location, lvl: ActionsLog::NOTICE, i_id: last_i_id).save
      end
    end
  end


end
