# A single word in the search index.
module Pose
  class Word < ActiveRecord::Base
    self.table_name_prefix = 'pose_'

    has_many :assignments, class_name: 'Pose::Assignment', dependent: :destroy


    # Returns the Pose::Word instances with the given texts.
    # @param [Array<String>]
    def self.factory texts
      texts.map {|text| Word.find_or_create_by text: text}
    end


    def self.remove_unused_words progress_bar = nil
      if Pose.has_sql_connection?
        # SQL database --> use an optimized query.
        Word.select("pose_words.id").
             joins("LEFT OUTER JOIN pose_assignments ON pose_assignments.word_id = pose_words.id").
             group("pose_words.id").
             having("COUNT(pose_assignments.id) = 0").
             delete_all
      else
        # Unknown database --> use metawhere.
        Word.select(:id).includes(:assignments).find_each(batch_size: 100) do |word|
          word.delete if word.assignments.size.zero?
          progress_bar.try(:increment)
        end
      end
    end
  end
end
