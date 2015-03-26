module Utils
  class << self
    def number_format number, dec, empty_replacement="-"
      if number.nil? or number == 0
        ret = empty_replacement
      else
        ret = sprintf("%0.#{dec}f", number.round(dec))
        ret = ret.gsub(/(\d)(?=\d{3}+\.)/, '\1,') if dec > 0
        ret = sprintf("%0.#{dec}f", number.round(dec)).gsub(/(\d)(?=\d{3}+$)/, '\1,') if dec == 0
        ret = ret.tr(',.','.,')
      end
      ret
    end

    def money_format number, dec, empty_replacement="-"
      num = number_format(number, dec, empty_replacement)
      num = "$ #{num}" unless num == empty_replacement
      num
    end

    def local_datetime_format time
      # TODO: DST support
      (time - (60 * 60 * 3)).strftime("%d/%m/%Y %H:%M") unless time.nil?
    end

    def local_date_format date
      date.strftime("%d/%m/%Y") unless date.nil?
    end
  end
end


class Numeric
  UNIDADES = ["", "un", "dos", "tres", "cuatro", "cinco", "seis", "siete", "ocho", "nueve", "diez", "once", "doce", "trece", "catorce", "quince", "dieciseis", "diecisiete", "dieciocho", "diecinueve", "veinte", "veintiun", "veintidos", "veintitres", "veinticuatro", "veinticinco", "veintiseis", "veintisiete", "veintiocho", "veintinueve"]
  DECENAS = ["", "diez", "veinte", "treinta", "cuarenta", "cincuenta", "sesenta", "setenta", "ochenta", "noventa"]
  CENTENAS = ["", "ciento", "doscientos", "trescientos", "cuatrocientos", "quinientos", "seiscientos", "setecientos", "ochocientos", "novecientos"]
  MILLONES = ["mill", "bill", "trill", "cuatrill"]
  def to_words
    final_text = ""
    sprintf( "%.2f", self ) =~ /([^\.]*)(\..*)?/
    int, dec = $1.reverse, $2 ? $2[1..-1] : ""
    int = int.scan(/.{1,6}/).reverse
    int = int.map{ |million| million.scan(/.{1,3}/).reverse}
    int.each_with_index do |sixdigit, index|
      i = int.length - index
      final_text += solve_million sixdigit
      if (i-2) >= 0
        final_text += " " + MILLONES[ i-2 ]
        final_text += sixdigit == ["1"] ? "ón" : "ones"
      end
    end
    final_text = " cero" if final_text.empty?
    final_text[1..-1]
  end

  private

  def solve_million sixdigit
    text = ""
    text += solve_thousand sixdigit.first
    if sixdigit.length > 1
      text += " mil"
      text += solve_thousand sixdigit.last
    end
    text
  end

  def solve_thousand threedigit
    text = ""
    return "error" if threedigit.length > 3
    text += " " + CENTENAS[ threedigit[2].to_i ] if threedigit.length > 2 && threedigit[2] != '0'
    if threedigit.length >= 2 && threedigit[1].ord > '2'.ord
      text += " " + DECENAS[ threedigit[1].to_i ] if threedigit[1] != '0'
      unit = threedigit[0].to_i
      text += " y" if unit != 0
      text += " " + UNIDADES[ unit ] if unit != 0
    else
      unit = threedigit[0..1].reverse.to_i
      text += " " + UNIDADES[ unit ] if unit != 0
    end
    text
  end

end
