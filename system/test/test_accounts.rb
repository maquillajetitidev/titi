require_relative 'prerequisites'

class AccountsTest < Test::Unit::TestCase
  def setup
    @transaction = Transaction.new("Test transaction", AccountPlan.new($settings))
  end

  def test_should_create_transaction
    assert @transaction.has_plan?
  end

  def test_transaction_cant_be_empty
    DB.transaction(rollback: :always, isolation: :uncommitted) do
      exception = assert_raise(RuntimeError) {@transaction.save}
      assert_equal(R18n.t.errors.empty_transaction, exception.message)
    end
end

  def test_should_allow_to_add_operations
    @transaction.add(loc: Location::S1, orig: "Recaudacion", dest: "Caja", amount: 1000)
    assert @transaction.has_operations? 1
    @transaction.add(loc: Location::S1, orig: "Recaudacion", dest: "Banco", amount: 500)
    assert @transaction.has_operations? 2
    assert_false @transaction.has_operations? 1
  end


  def test_transaction_description_cant_be_empty
    DB.transaction(rollback: :always, isolation: :uncommitted) do
      transaction = Transaction.new("     " , AccountPlan.new($settings))
      transaction.add(loc: Location::S1, orig: "Recaudacion", dest: "Caja", amount: 1000)
      exception = assert_raise(Sequel::ValidationFailed) {transaction.save}
      assert_equal("#{t.fields.t_desc.to_sym} #{t.errors.presence}", exception.message)
    end
  end


  def test_multiple_transactions
    DB.transaction(rollback: :always, isolation: :uncommitted) do
      transaction = Transaction.new("1 Deuda original (desglosar)" , AccountPlan.new($settings))
      transaction.add(orig: "TODOS LOS MATERIALES", dest: "Fondo de comercio a pagar", amount: 100000)
      transaction.save
      new_trans = AccountTransaction[transaction.t_id]
      assert new_trans.AccountRecords.size == 1, "cantidad equivocada de registros"
      # puts transaction

      transaction = Transaction.new("2 Venta de mercaderia" , AccountPlan.new($settings))
      transaction.add(orig: "Caja", dest: "Venta por mostrador", amount: 10000, order: 666, loc: Location::S1)
      transaction.add(orig: "Banco", dest: "Venta por mostrador", amount: 5000, order: 666, loc: Location::S1)
      transaction.add(orig: "IIBB", dest: "IIBB a pagar", amount: 450, order: 666, loc: Location::S1)
      transaction.add(orig: "Comisiones a pagar", dest: "Comisiones", amount: 1500, order: 666, loc: Location::S1)
      transaction.add(orig: "Costo mercaderia vendida", dest: "TODOS LOS PRODUCTOS", amount: 10000, order: 666, loc: Location::S1)
      transaction.save
      new_trans = AccountTransaction[transaction.t_id]
      assert new_trans.AccountRecords.size == 5, "cantidad equivocada de registros"
      # puts transaction

      transaction = Transaction.new("2b Cobro de comisiones" , AccountPlan.new($settings))
      transaction.add(orig: "Comisiones", dest: "Caja", amount: 1500, loc: Location::S1)
      transaction.save
      new_trans = AccountTransaction[transaction.t_id]
      assert new_trans.AccountRecords.size == 1, "cantidad equivocada de registros"
      # puts transaction

      transaction = Transaction.new("3 Compra de impresora" , AccountPlan.new($settings))
      transaction.add(orig: "Bienes de uso", dest: "Tarjeta de credito a pagar", amount: 1000, loc: Location::W2)
      transaction.save
      new_trans = AccountTransaction[transaction.t_id]
      assert new_trans.AccountRecords.size == 1, "cantidad equivocada de registros"
      # puts transaction

      transaction = Transaction.new("4 Compra de mercaderia" , AccountPlan.new($settings))
      transaction.add(orig: "Liquido corporal blanco", dest: "Laca", amount: 230)
      transaction.add(orig: "Liquido corporal rojo", dest: "Laca", amount: 250)
      transaction.add(orig: "Laca", dest: "Caja", amount: 480)
      transaction.add(orig: "Fletes", dest: "Caja", amount: 20)
      transaction.save
      new_trans = AccountTransaction[transaction.t_id]
      assert new_trans.AccountRecords.size == 4, "cantidad equivocada de registros"
      # puts transaction

      transaction = Transaction.new("5 Aumento del 10% de la mercaderia recien comprada" , AccountPlan.new($settings))
      transaction.add(orig: "Liquido corporal blanco", dest: "Resultado por tenencia", amount: 23)
      transaction.add(orig: "Liquido corporal rojo", dest: "Resultado por tenencia", amount: 25)
      transaction.save
      new_trans = AccountTransaction[transaction.t_id]
      assert new_trans.AccountRecords.size == 2, "cantidad equivocada de registros"
      # puts transaction
    end
  end

  def test_AccountPlan_should_detect_invalid_accounts
    plan = AccountPlan.new($settings)
    plan.load
    assert_false plan.account_exists? "INVALID"
    assert plan.account_exists?("Bienes de cambio")

    assert_false plan.account_valid?("INVALID")
    assert_false plan.account_valid?("Bienes de cambio")
    assert plan.account_valid?("Caja")
  end

  def test_operations_should_not_be_on_same_group
    account_plan = AccountPlan.new($settings)
    transaction = Transaction.new("Compra de liquido corporal mal registrada", account_plan)
    orig = "Liquido corporal blanco"
    dest = "Caja"
    exception = assert_raise(RuntimeError) {transaction.add(orig: orig, dest: dest, amount: 500)}
    assert_equal(R18n.t.errors.accounts_of_same_group(orig, dest), exception.message)
  end

  def test_operation_shoud_have_a_transaction
    DB.transaction(rollback: :always, isolation: :uncommitted) do
      record = AccountRecord.new( r_orig: "Viaticos", r_dest: "Caja", r_amount: "10")
      exception = assert_raise(Sequel::ValidationFailed) { record.save }
      assert_equal(" #{R18n.t.errors.record_without_transaction}", exception.message)
    end
  end

  def test_operation_shoud_have_origin_destination_and_amount
    account_plan = AccountPlan.new($settings)
    transaction = Transaction.new("Registro de viaticos sin destino", account_plan)
    orig = "Viaticos"
    dest = "Caja"
    amount = 500

    exception = assert_raise(ArgumentError) {transaction.add(dest: dest, amount: amount)}
    assert_equal("missing keyword: orig", exception.message)

    exception = assert_raise(ArgumentError) {transaction.add(orig: orig, amount: amount)}
    assert_equal("missing keyword: dest", exception.message)

    exception = assert_raise(ArgumentError) {transaction.add(orig: orig, dest: dest)}
    assert_equal("missing keyword: amount", exception.message)
  end


end
