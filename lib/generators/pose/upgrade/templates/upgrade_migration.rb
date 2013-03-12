class PoseUpgrade < ActiveRecord::Migration

  def change
    rename_column :pose_assignments, :pose_word_id, :word_id
  end

end
