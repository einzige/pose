# encoding: UTF-8
# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended to check this file into your version control system.

ActiveRecord::Schema.define(:version => 20130308144915) do

  create_table "posable_ones", :force => true do |t|
    t.string  "text"
    t.boolean "private"
  end

  create_table "posable_twos", :force => true do |t|
    t.string  "text"
    t.boolean "private"
  end

  create_table "pose_assignments", :force => true do |t|
    t.integer "word_id",                    :null => false
    t.integer "posable_id",                 :null => false
    t.string  "posable_type", :limit => 60, :null => false
  end

  add_index "pose_assignments", ["posable_id"], :name => "index_pose_assignments_on_posable_id"
  add_index "pose_assignments", ["word_id"], :name => "index_pose_assignments_on_word_id"

  create_table "pose_words", :force => true do |t|
    t.string "text", :limit => 80, :null => false
  end

  add_index "pose_words", ["text"], :name => "index_pose_words_on_text"

end
