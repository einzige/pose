module Pose
  module BaseAdditions

    def posify &block
      include Pose::ModelAdditions
      self.pose_content = block_given? ? block : :pose_content.to_proc
    end

  end
end
