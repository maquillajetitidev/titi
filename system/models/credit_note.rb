require 'sequel'

class Credit_note < Sequel::Model
  ATTRIBUTES = [:cr_id, :cr_desc, :cr_status, :cr_ammount, :o_id, :created_at]
  COLUMNS = [:cr_id, :cr_desc, :cr_status, :cr_ammount, :credit_notes__o_id, :credit_notes__created_at]

  def change_status status, o_id
    o_id = o_id.to_i
    self.cr_status = status
    save columns: Credit_note::ATTRIBUTES
    current_user_id =  User.new.current_user_id
    current_location = User.new.current_location[:name]
    message = R18n.t.actions.changed_order_status(ConstantsTranslator.new(status).t)
    log = ActionsLog.new.set(msg: message, u_id: current_user_id, l_id: current_location, lvl: ActionsLog::INFO)
    log.set(o_id: o_id) unless o_id == 0
    log.save
    message
  end
end

class Cr_status
  READY = "READY"
  USED = "USED"
  VOID = "VOID"
end
