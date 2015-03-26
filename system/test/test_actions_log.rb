require_relative 'prerequisites'

class ActionsLogTest < Test::Unit::TestCase

  def test_create_log_template
    #  DB.transaction(rollback: :always, isolation: :uncommitted) do
    # current_user_id =  State.current_user.user_id
    # current_location = State.current_location_name
    # message = "#{R18n.t.actions.changed_item_status(ConstantsTranslator.new(Item::VOID).t)}. Razon: #{reason}"
    # log = ActionsLog.new.set(msg: message, u_id: current_user_id, l_id: origin, lvl: ActionsLog::NOTICE, i_id: @values[:i_id], o_id: order.o_id)
    # end
  end

  def test_should_validate_msg_and_user
    log = ActionsLog.new.set(msg: "Dummy", u_id: 1)
    assert( log.valid? )
    log.u_id = nil
    assert_false( log.valid?, "No user given validation" )
    log.msg = nil
    log.u_id = 1
    assert_false( log.valid?, "No message given validation" )
  end

  def test_should_reject_invalid_id
    log = ActionsLog.new.set(msg: "Test log", u_id: 1)
    log.b_id = "sdfsd"
    assert_false( log.valid?, "Accepts an invalid bulk_id" )
  end

  def test_full_text_search
    str =  "marron petaca chatelet recalculan 1071"
    terms = str.scan(/[\w'-]+/)
    terms = terms.map { |term| "+#{term}*"}
    placeholder = DB[:actions_log].full_text_sql(:msg, terms, {boolean: true})
    msg = ActionsLog.select(:msg).filter{ placeholder }.first[:msg]
    assert_equal "Recalculando producto 1071: Sombra individual Chatelet Petaca Individual 3gr Marron Nro 31", msg
  end

end
