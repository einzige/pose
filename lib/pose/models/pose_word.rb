# A single word in the search index.
class PoseWord < ActiveRecord::Base
  has_many :pose_assignments

  attr_accessible :text

  def self.remove_unused_words progress_bar = nil
    if ActiveRecord::Base.connection.is_a?(ActiveRecord::ConnectionAdapters::PostgreSQLAdapter)
      # Will generate something like:
      #
      # DELETE FROM "pose_words" WHERE "pose_words"."id" IN
      # (SELECT "pose_words"."id" FROM "pose_words" INNER JOIN "pose_assignments" ON "pose_assignments"."pose_word_id" = "pose_words"."id"
      # HAVING.... GROUP BY "pose_words"."id")
      PoseWord.delete_all(id: PoseWord.select("pose_words.id").
                          joins("LEFT OUTER JOIN pose_assignments ON pose_assignments.pose_word_id = pose_words.id").
                          group("pose_words.id").
                          having("COUNT(pose_assignments.id) = 0"))
    else
      # NOTE (SZ): do not use find_each uses batch_size == 100.
      # Use find_in_batches instead.
      #
      PoseWord.select(:id).find_in_batches.each(include: [:pose_assignments], batch_size: 5000) do |pose_word|
        pose_word.delete if pose_word.pose_assignments.size == 0
        progress_bar.inc if progress_bar
      end
    end
  end
end
