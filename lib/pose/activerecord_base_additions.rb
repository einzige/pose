# Additions to ActiveRecord::Base.
module Pose
  module ActiveRecordBaseAdditions

    # Defines the searchable content in ActiveRecord objects.
    def posify &block
      raise "Error while posifying class '#{name}': " \
            "You must provide a block that returns the searchable content to 'posify'." unless block_given?

      include ModelClassAdditions
      self.pose_content = block
    end
  end
end
