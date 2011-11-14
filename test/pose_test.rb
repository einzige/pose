require 'test_helper'

def setup_db
  ActiveRecord::Schema.define(:version => 1) do

    create_table 'test_posables' do |t|
      t.string 'text'
    end

    create_table "pose_assignments", :force => true do |t|
      t.integer "word_id",                     :null => false
      t.integer "wordable_id",                 :null => false
      t.string  "wordable_type", :limit => 20, :null => false
    end

    create_table "words", :force => true do |t|
      t.string "text", :limit => 80, :null => false
    end
  end
end

def teardown_db
  ActiveRecord::Base.connection.tables.each do |table|
    ActiveRecord::Base.connection.drop_table(table)
  end
end


class TestPosable < ActiveRecord::Base
  posify
end



class PoseTest < ActiveSupport::TestCase
  def setup
     setup_db
   end

   def teardown
     teardown_db
   end

  test "truth" do
    assert_kind_of Module, Pose
  end
  
  test 'foo' do
    t = TestPosable.new
  end
  
end
