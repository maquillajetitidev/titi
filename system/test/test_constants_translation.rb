require_relative 'prerequisites'

class ConstantsTranslatorTest < Test::Unit::TestCase

  def test_should_translate_OPEN_constant
    assert_equal R18n::t.constant.OPEN, ConstantsTranslator.new("OPEN").t
  end
end