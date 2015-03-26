require 'test/unit'
require 'rack/test'
require 'sequel'
require "awesome_print"
require 'sinatra'
require 'sinatra/r18n'
require 'sinatra/config_file'
require 'pdfkit'
require_relative '../sinatra/csrf'

config_file '../../config.yml'
require 'tree'
ENV["TZ"] = "GMT"

register Sinatra::R18n
R18n.default_places { './locales' }
R18n.set('es') # during tests it must be set explicitly
include R18n::Helpers

require 'encrypted_cookie'
use Rack::Session::EncryptedCookie, secret: settings.cookie_secret, expire_after: settings.session_length

require_relative '../helpers/init'
require_relative '../models/init'
# require_relative '../models/stdout_logger'

$settings = Settings.new '../config.yml'

State.current_user = User.new.get_user("aburone")

module Test::Unit::Assertions
  def assert_false(object, message="")
    assert_equal(false, object, message)
  end
end

def get_new_label
  label = Label.filter(I_status: Label::NEW).first
  if label.class == NilClass
    Label.new.create 1
    label = Label.filter(I_status: Label::NEW).first
  end
  label
end

def get_printed_label
  label = get_new_label
  label.change_status(Item::PRINTED, nil)
  label
end

def get_new_item
  item = Item.filter(I_status: Item::NEW).first
  if item.class == NilClass
    Label.new.create 1
    item = Item.filter(I_status: Item::NEW).first
  end
  item
end

def get_assigned_item
  DB.transaction(rollback: :always, isolation: :uncommitted) do
    label = get_printed_label
    Product.new.get_rand.add_item label, nil
    Item[label.i_id]
  end
end


class Item
  def get_rand
    max_pos = Item.filter(i_status: Item::READY).count(:i_id)
    if max_pos > 0
      rnd = rand(max_pos)
      return Item.filter(i_status: Item::READY).limit(1, rnd).first
    else
      raise "No items available"
    end
  end
end

class Bulk
  def get_rand
    max_pos = Bulk.filter(b_status: [Bulk::NEW, Bulk::IN_USE]).count(:b_id)
    if max_pos > 0
      rnd = rand(max_pos)
      return Bulk.filter(b_status: [Bulk::NEW, Bulk::IN_USE]).limit(1, rnd).first
    else
      raise "No bulks available"
    end
  end
end

class Order
  def get_rand
    max_pos = Order.filter(o_status: Order::FINISHED).count(:o_id)
    if max_pos > 0
      rnd = rand(max_pos)
      return Order.filter(o_status: Order::FINISHED).limit(1, rnd).first
    else
      raise "No orders available"
    end
  end
end

class Product
  def get_rand
    max_pos = Product.filter(archived: false).count(:p_id)
    rnd = rand(max_pos)
    prod = Product.filter(archived: false).limit(5, rnd).first
    Product.new.get prod.p_id
  end
end

class Material
  def get_rand
    max_pos = Material.count(:m_id)
    if max_pos > 0
      rnd = rand(max_pos)
      return Material.limit(1, rnd).first
    else
      raise "No materials available"
    end
  end
end

class Distributor
  def get_rand
    max_pos = Distributor.count(:d_id)
    if max_pos > 0
      rnd = rand(max_pos)
      return Distributor.limit(1, rnd).first
    else
      raise "No distributors available"
    end
  end
end

class User
  def current_location= new_location
    # Thread.current.thread_variable_set(:current_location, {name: new_location, translation: ConstantsTranslator.new(new_location).t})
    State.current_location = {name: new_location, translation: ConstantsTranslator.new(new_location).t}
  end

  # def current_user_id= new_user_id
  #   # Thread.current.thread_variable_set(:user_id, new_user_id)
  #   State.current_user = user
  # end
end
