class ConstantsTranslator
  def initialize status
    @status = eval("R18n::t.constant.#{status}").to_s unless status.nil?
    @status ||= ""
  end

  def t
    @status
  end
end