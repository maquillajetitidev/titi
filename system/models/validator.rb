class Validator
include R18n::Helpers

  def validate_packaging_order_params order, product, label, params, session, flash
    error = false
    current_user_id =  User.new.current_user_id
    current_location = User.new.current_location[:name]

    if order.nil?
      flash[:error_invalid_order] = R18n::t.errors.invalid_order_id
      log = ActionsLog.new.set(msg: "#{R18n::t.errors.invalid_order_id} #{params[:label]}", u_id: current_user_id, l_id: current_location, lvl:  ActionsLog::WARN)
      log.save
      error = true
    end

    if product.nil?
      flash[:error_inexistent_product] = R18n::t.errors.inexistent_product
      error = true
    end

    if params[:label].empty?
      flash[:error_bad_label_reading] = R18n::t.errors.bad_label_reading
      error = true
    elsif label.nil?
      flash[:error_inexistent_label] = R18n::t.errors.inexistent_label
      log = ActionsLog.new.set(msg: "#{R18n::t.errors.inexistent_label} #{params[:label]}", u_id: current_user_id, l_id: current_location, lvl:  ActionsLog::WARN)
      log.save
      error = true
    elsif label.i_status == Item::PRINTED
      error = false
    elsif label.i_status == Item::ASSIGNED or label.i_status == Item::MUST_VERIFY
      message = R18n::t.errors.previously_assigned_label
      flash[:warning_assigned_label] = message
      log = ActionsLog.new.set(msg: "#{message}", u_id: current_user_id, l_id: current_location, lvl:  ActionsLog::NOTICE, i_id: label.i_id)
      log.save
      error = true
    elsif label.i_status == Item::VOID
      flash[:error_void_label] = R18n::t.errors.void_label
      log = ActionsLog.new.set(msg: "#{R18n::t.errors.void_label}", u_id: current_user_id, l_id: current_location, lvl:  ActionsLog::ERROR, i_id: label.i_id)
      log.save
      error = true
    elsif label.i_status == Item::NEW
      flash[:error_invalid_label_status] = R18n::t.errors.label_wasnt_printed
      log = ActionsLog.new.set(msg: "#{R18n::t.errors.label_wasnt_printed}", u_id: current_user_id, l_id: current_location, lvl:  ActionsLog::ERROR, i_id: label.i_id)
      log.save
      error = true
    end
    error
  end
end
