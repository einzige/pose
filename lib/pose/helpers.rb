# Internal helper methods for the Pose module.
# TODO: remove
module Pose
  module Helpers
    class <<self

      def is_sql_database?
        ['ActiveRecord::ConnectionAdapters::PostgreSQLAdapter',
         'ActiveRecord::ConnectionAdapters::SQLite3Adapter'].include? ActiveRecord::Base.connection.class.name
      end

    end
  end
end
