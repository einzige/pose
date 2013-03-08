# Assigns searchable objects to words in the search index.
module Pose
  class Assignment < ActiveRecord::Base
    attr_accessible :word, :posable

    belongs_to :word, class_name: 'Pose::Word'
    belongs_to :posable, polymorphic: true

    # Removes all Assignments for the given class.
    def self.delete_class_index clazz
      Assignment.delete_all(posable_type: clazz.name)
    end

    # Removes all Assignments that aren't used anymore.
    def self.cleanup_orphaned_pose_assignments progress_bar = nil
      Assignment.find_each(include: [:posable, :word], batch_size: 5000) do |assignment|
        progress_bar.increment if progress_bar

        # Delete the assignment if the posable object no longer exists.
        if assignment.posable.nil?
          puts "deleting assignment '#{assignment.id}' because the posable object no longer exists."
          assignment.delete
          next
        end

        # Delete the assignment if the Pose::Word for it no longer exists.
        if assignment.word.nil?
          puts "deleting assignment '#{assignment.id}' because its word no longer exists."
          assignment.delete
        end
      end
    end
  end
end
