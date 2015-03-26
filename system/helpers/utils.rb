module Utils
  class << self
    def deep_copy(obj)
      Marshal.load(Marshal.dump(obj))
    end

    def is_numeric? v
      case(v)
      when /\A\s*[+-]?\d+\.\d+\z/
          return true
      when /\A\s*[+-]?\d+(\.\d+)?[eE]\d+\z/
          return true
      when /\A\s*[+-]?\d+\z/
          return true
      else
          return false
      end
    end

    def as_number v
      case(v)
      when /\A\s*[+-]?\d+\.\d+\z/
          v.to_f
      when /\A\s*[+-]?\d+\,\d+\z/
          v.to_s.gsub(',', '.').to_f
      when /\A\s*[+-]?\d+(\.\d+)?[eE]\d+\z/
          v.to_f
      when /\A\s*[+-]?\d+\z/
          v.to_i
      when /\d/
        Utils::as_number v.gsub(/[^\d|.|,]/, '')
      else
        return 0
      end
    end

  end
end

