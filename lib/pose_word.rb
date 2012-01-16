# A single word in the search index.
class PoseWord < ActiveRecord::Base
  has_many :pose_assignments

  def self.remove_unused_words
    PoseWord.find_each(:include => [:pose_assignments], :batch_size => 5000) do |pose_word|
      if pose_word.pose_assignments.size == 0
        pose_word.delete
        next
      end
    end
  end
end
