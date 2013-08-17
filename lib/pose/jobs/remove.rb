require 'ruby-progressbar'

module Pose
  module Jobs
    class Remove
      attr_reader :klass

      # @param [String, Class] clazz
      def initialize(clazz)
        @klass = case clazz
                   when String
                     clazz.constantize
                   when Class
                     clazz
                   else
                     raise ArgumentError, "Class or String expected, #{clazz.class} given"
                 end
      end

      def perform
        Pose::Assignment.delete_class_index(klass)
        puts "Search index for class #{klass.name} deleted.\n\n"
      end
    end
  end
end