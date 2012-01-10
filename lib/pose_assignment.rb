# Assigns searchable objects to words in the search index.
class PoseAssignment < ActiveRecord::Base
  belongs_to :pose_word
  belongs_to :posable, :polymorphic => true

  # Removes all PoseAssignments that aren't used anymore.
  def self.cleanup_orphaned_pose_assignments
    PoseAssignment.find_each(:include => [:posable, :pose_word], :batch_size => 5000) do |assignment|

      # Delete the assignment if the posable object no longer exists.
      if assignment.posable.nil?
        puts "deleting assignment '#{assignment.id}' because the posable object no longer exists."
        assignment.delete
        next
      end

      # Delete the assignment if the PoseWord for it no longer exists.
      puts "pose_word: #{assignment.id} - #{assignment.pose_word}"
      puts "pose_word: #{assignment.pose_word.try :text}"
      if assignment.pose_word.nil?
        puts "deleting assignment '#{assignment.id}' because its word no longer exists."
        assignment.delete
      end
    end
  end
end