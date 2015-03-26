class OpenStruct
  # Allow awesome_print to work (with patch to AwesomePrint::Inspector defined below)
  if defined?(AwesomePrint)
    def each_pair &block
      @table.each_pair(&block)
    end
  end
end

## Patch inspector so it recognizes OpenStruct
if defined?(AwesomePrint::Inspector)
  module AwesomePrint
    class Inspector
      private
        alias_method :printable_original, :printable
        def printable(object)
          case object
          when OpenStruct  then :struct
          else printable_original(object)
          end
        end

    end
  end
end
