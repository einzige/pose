# Additions to ActiveRecord::Base.
module Pose
  module ActiveRecordBaseAdditions

    # Defines the searchable content in ActiveRecord objects.
    def posify *source_methods, &block
      include ModelClassAdditions

      self.pose_content = proc do
        text_chunks = source_methods.map { |source| send(source) }
        text_chunks << instance_eval(&block) if block
        text_chunks.reject(&:blank?).join(' ')
      end
    end
  end
end
