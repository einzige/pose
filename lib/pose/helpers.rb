# Internal helper methods for the Pose module.
# TODO: remove
module Pose
  module Helpers
    class <<self

      def is_sql_database?
        ['ActiveRecord::ConnectionAdapters::PostgreSQLAdapter',
         'ActiveRecord::ConnectionAdapters::SQLite3Adapter'].include? ActiveRecord::Base.connection.class.name
      end


      # Makes the given input an array.
      def make_array input
        [input].flatten
      end


    end
  end
end
