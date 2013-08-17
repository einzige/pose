require 'ruby-progressbar'

module Pose
  module Jobs
    class ReindexAll
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
        progress_bar = ProgressBar.create title: "  reindexing", total: klass.count

        klass.find_each do |instance|
          instance.update_pose_words
          progress_bar.increment
        end

        progress_bar.finish
      end
    end
  end
end