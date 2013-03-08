class PoseUpgrade < ActiveRecord::Migration

  def change
    change_table 'pose_assignments' do |t|
      t.rename :pose_word_id, :word_id
    end
  end

end
