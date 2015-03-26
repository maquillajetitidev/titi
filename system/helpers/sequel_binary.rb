module Sequel
  class Model
    module ClassMethods
 
      def [](*args)
        # p "BINARY search"
        args = args.first if args.size <= 1
        args.is_a?(Hash) ? dataset[args] : (primary_key_lookup(args) unless args.nil?)
      end

      # Reset the cached fast primary lookup SQL if a simple table and primary key
      # are used, or set it to nil if not used.
      def reset_fast_pk_lookup_sql
        @fast_pk_lookup_sql = if @simple_table && @simple_pk
          # "SELECT * FROM #@simple_table WHERE #@simple_pk = ".freeze
          "SELECT * FROM #@simple_table WHERE #@simple_pk LIKE BINARY ".freeze
        end
        @fast_instance_delete_sql = if @simple_table && @simple_pk
          "DELETE FROM #@simple_table WHERE #@simple_pk = ".freeze
        end
      end

    end
  end
end
