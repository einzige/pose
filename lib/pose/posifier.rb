module Pose
  module Posifier
    extend ActiveSupport::Concern

    module ClassMethods
      def posify &block
        include Pose
        self.pose_content = block_given? ? block : :pose_content.to_proc
      end
    end
  end
end
ActiveRecord::Base.send :include, Pose::Posifier
