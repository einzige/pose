module Pose
  module BaseAdditions
    extend ActiveSupport::Concern

    module ClassMethods
      def posify &block
        include Pose::ModelAdditions
        self.pose_content = block_given? ? block : :pose_content.to_proc
      end
    end
  end
end
