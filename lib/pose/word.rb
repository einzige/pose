# A single word in the search index.
module Pose
  class Word < ActiveRecord::Base
    self.table_name_prefix = 'pose_'

    has_many :assignments, class_name: 'Pose::Assignment', dependent: :destroy


    # Returns the Pose::Word instances with the given text.
    # @param [Array<String>]
    def self.factory texts
      texts.map {|text| Word.find_or_create_by text: text}
    end


    # Returns whether the currently used database
    # is a relational one.
    def self.is_sql_database?
      ['ActiveRecord::ConnectionAdapters::PostgreSQLAdapter',
       'ActiveRecord::ConnectionAdapters::SQLite3Adapter'].include? ActiveRecord::Base.connection.class.name
    end


    def self.remove_unused_words progress_bar = nil
      if Word.is_sql_database?
        # SQL database --> use an optimized query.
        Word.delete_all(id: Word.select("pose_words.id").
                                 joins("LEFT OUTER JOIN pose_assignments ON pose_assignments.word_id = pose_words.id").
                                 group("pose_words.id").
                                 having("COUNT(pose_assignments.id) = 0"))
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
