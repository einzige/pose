# A single word in the search index.
module Pose
  class Word < ActiveRecord::Base
    self.table_name_prefix = 'pose_'

    has_many :assignments, class_name: 'Pose::Assignment', dependent: :destroy

    def self.remove_unused_words progress_bar = nil
      if Helpers.is_sql_database?
        # SQL database --> use an optimized query.
        Word.delete_all(id: Word.select("pose_words.id").
                                 joins("LEFT OUTER JOIN pose_assignments ON pose_assignments.word_id = pose_words.id").
                                 group("pose_words.id").
                                 having("COUNT(pose_assignments.id) = 0"))
      else
        # Unknown database --> use the standard Rails API.
        Word.select(:id).includes(:assignments).find_each(batch_size: 100) do |word|
          word.delete if word.assignments.size == 0
          progress_bar.increment if progress_bar
        end
      end
    end
  end
end
