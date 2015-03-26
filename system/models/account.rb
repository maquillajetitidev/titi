# coding: utf-8
require 'rubytree'

class AccountTransaction < Sequel::Model(:accounts_transactions)
  one_to_many :AccountRecords, key: :t_id
  def print
    out = "\n"
    out += "#{self.class} #{sprintf("%x", self.object_id)}:\n"
    out += "\tt_id:               #{@values[:t_id]}\n"
    out += "\tt_desc:              #{@values[:t_desc]}\n"
    out
  end
  def validate
    super
    validates_schema_types [:t_id, :t_id]
    validates_schema_types [:t_desc, :t_desc]
    errors.add(t.fields.t_desc.to_sym, t.errors.presence) if !t_desc || t_desc.empty?
  end
end

class AccountRecord < Sequel::Model(:accounts_records)
  many_to_one :AccountTransaction, key: :t_id
  def validate
    super
    errors.add("", t.errors.record_without_transaction) if !t_id
  end
end


class AccountPlan
  attr_accessor :accounts
  def initialize settings
    @accounts_file = File.expand_path("../../../#{settings.accounts_file}", __FILE__)
  end
  def save
    File.open( @accounts_file,'w') { |file| file.puts @accounts.to_yaml }
  end
  def load
    begin
      @accounts = YAML::load( File.read( @accounts_file ))
    rescue
      @accounts = Tree::TreeNode.new("Cuentas", "Plan de cuentas")
    end
  end
  def account_exists? account
    return @accounts.find(account) ? true : false
  end
  def account_valid? account
    node = @accounts.find(account)
    return false unless node
    node.is_leaf?
  end
  def group account
    node = @accounts.find(account)
    while node.level > 1
      node = node.parent
    end
    node
  end
end


class Operation
  attr_reader :loc, :orig, :dest, :amount, :order
  def initialize(loc, orig, dest, amount, order)
    @loc = loc
    @orig = orig
    @dest = dest
    @amount = amount
    @order = order
  end

end


class Transaction

  def initialize description, plan
    @operations = []
    @description = description
    @plan = plan
    @plan_tree = plan.load
    @total = 0
    @transaction = AccountTransaction.new
    @transaction.t_desc = @description
  end

  def t_id
    @transaction.t_id
  end

  def print
    out = "\n"
    out += "#{@description} (#{@transaction.t_id})"
    out += " $ #{l @total}" if @total != 0
    @operations.map do |o|
      out += "\n#{o.orig} #{l o.amount} -> #{o.dest} (#{l o.amount}) "
      out += "Orden:#{l o.order}" if o.order
      out += "@#{ConstantsTranslator.new(o.loc).t}" if o.loc
    end
    out
  end

  def add(loc: nil, orig:, dest:, amount:, order: nil)
    raise t.errors.inexistent_account(orig) unless @plan.account_exists?(orig)
    raise t.errors.inexistent_account(dest) unless @plan.account_exists?(dest)
    raise t.errors.invalid_account(orig) unless @plan.account_valid?(orig)
    raise t.errors.invalid_account(dest) unless @plan.account_valid?(dest)
    raise t.errors.accounts_of_same_group(orig, dest) if @plan.group(orig).name == @plan.group(dest).name


    operation = Operation.new(loc, orig, dest, amount, order)
    @operations << operation
    @total += amount if orig == "Caja" or orig == "Banco"
    @total -= amount if dest == "Caja" or dest == "Banco"
  end

  def save
    # current_user_id =  User.new.current_user_id
    # current_location = User.new.current_location[:name]
    # BookRecord.new(b_loc: current_location, o_id: @order.o_id, created_at: Time.now, type: "Venta mostrador", description: "#{items.count}", amount: @cart_total).save
    DB.transaction do
      raise R18n.t.errors.empty_transaction if @operations.empty?
      @transaction.save
      @operations.map do |o|
        record = AccountRecord.new( r_orig: o.orig, r_dest: o.dest, r_amount: o.amount)
        record.r_loc = o.loc if o.loc
        record.o_id = o.order if o.order
        @transaction.add_AccountRecord( record )
      end
    end
  end

  def has_plan?
    @plan_tree.size > 0
  end

  def has_operations? (qty=:any)
    qty==:any ? @operations.size>0 : @operations.size==qty
  end
end
