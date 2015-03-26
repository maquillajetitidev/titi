require_relative 'prerequisites'

class R18nTest < Test::Unit::TestCase

  def setup
  end

  def test_setup
    # en = R18n::locale('en')
    # # p en
    # p en.class
    # R18n::change(en)
    # p r18n.locale

        # i18n = R18n::I18n.new('en')
    # R18n.set(i18n)
    # p R18n.get
  end

end


# p R18n.get.actions.finish
# p t.actions.finish


# R18N = R18n::I18n.new(['es', 'en'], './locales')

# register Sinatra::R18n
# set :root, File.dirname(__FILE__)
# locale = R18n.locale('es')
# R18n::I18n.default = 'es'
# # R18n.default_places { './locales' }

# kk = R18n::Loader::YAML.new('./locales/es.yml')
# p kk
# p kk.methods
# p kk.available

# R18n.set('es', './locales/es.yml')

# include R18n::Helpers

# p locale.title
# p R18n::get
# p locale.week_start
# p  t.actions.finish


# localizacion de numeros meses y demas
# locale = R18n.locale('en')
# p locale.methods


# i18n = R18n::I18n.new('es', './locales')
# include R18n::Helpers
# p i18n.methods
# p i18n.l one
# p i18n.t.actions.finish
# p i18n.translation_places
# p t.actions.finish

# locale_class = Class.new(R18n::Locale) do
#   set :one => 1
#   set :two => 2
#   set es: './locales/es.yml'
# end
# t = locale_class.new
# p t.one
# p t.two
# p t.es
