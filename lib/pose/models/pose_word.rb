# A single word in the search index.
class PoseWord < ActiveRecord::Base
  has_many :pose_assignments
  attr_accessible :word

  def self.remove_unused_words progress_bar = nil
    PoseWord.find_each(include: [:pose_assignments], batch_size: 5000) do |pose_word|
      pose_word.delete if pose_word.pose_assignments.size == 0
      progress_bar.inc if progress_bar
    end
  end
end
