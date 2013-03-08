class AddPoseTables < ActiveRecord::Migration

  def self.up
    drop_table 'pose_assignments'
    drop_table 'pose_words'
  end

  def self.down
    create_table "pose_assignments" do |t|
      t.integer "word_id",                 null: false
      t.integer "posable_id",              null: false
      t.string  "posable_type", limit: 60, null: false
    end
    add_index "pose_assignments", :word_id
    add_index "pose_assignments", :posable_id

    create_table "pose_words" do |t|
      t.string "text", limit: 80, null: false
    end
    add_index "pose_words", :text
  end
end

