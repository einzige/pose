require "spec_helper"

ActiveRecord::Base.establish_connection(:adapter => "sqlite3", :database => ":memory:")

class TestPosable < ActiveRecord::Base
  posify
  
  def pose_content
    [text]
  end
end

def setup_db
  ActiveRecord::Schema.define(:version => 1) do

    create_table 'test_posables' do |t|
      t.string 'text'
    end

    create_table "pose_assignments" do |t|
      t.integer "pose_word_id",                     :null => false
      t.integer "posable_id",                 :null => false
      t.string  "posable_type", :limit => 20, :null => false
    end

    create_table "pose_words" do |t|
      t.string "text", :limit => 80, :null => false
    end
  end
end

def teardown_db
  ActiveRecord::Base.connection.tables.each do |table|
    ActiveRecord::Base.connection.drop_table(table)
  end
end

describe Pose do
  subject { TestPosable.new }

  before :all do
    setup_db
    Pose::CONFIGURATION[:search_in_tests] = true
  end

  after :all do
    teardown_db
    Pose::CONFIGURATION[:search_in_tests] = false
  end
  
  describe 'associations' do
    it 'allows to access the associated words of a posable object directly' do
      subject.should have(0).pose_words
      subject.pose_words << PoseWord.new(:text => 'one')
      subject.should have_pose_words(['one'])
    end
  end

  describe 'change_pose_words' do

    context "in the 'test' environment" do
      after :each do
        Pose::CONFIGURATION[:search_in_tests] = true
      end
      
      it "doesn't calls update_pose_words in tests if the test flag is not enabled" do
        Pose::CONFIGURATION[:search_in_tests] = false
        subject.should_not_receive :update_pose_words
        subject.change_pose_words
      end

      it "calls update_pose_words in tests if the test flag is enabled" do
        Pose::CONFIGURATION[:search_in_tests] = true
        subject.should_receive :update_pose_words
        subject.change_pose_words
      end
    end
    
    context "in the 'production' environment' do" do
      before :each do
        @old_env = Rails.env
        Rails.env = 'production'
      end
      
      after :each do
        Rails.env = @old_env
      end
      
      it "calls update_pose_words" do
        subject.should_receive :update_pose_words
        subject.change_pose_words
      end
    end
  end

  describe 'update_pose_words' do

    it 'saves the words for search' do
      subject.text = 'foo bar'
      subject.update_pose_words
      subject.should have(2).pose_words
      subject.should have_pose_words ['foo', 'bar']
    end

    it 'updates the search index when the text is changed' do
      subject.text = 'foo'
      subject.save!
      
      subject.text = 'other text'
      subject.update_pose_words

      subject.should have_pose_words ['other', 'text']
    end

    it "doesn't create duplicate words" do
      subject.text = 'foo foo'
      subject.save!
      subject.should have(1).pose_words
    end
  end

  describe 'get_words_to_remove' do

    it "returns an array of word objects that need to be removed" do
      word1 = PoseWord.new :text => 'one'
      word2 = PoseWord.new :text => 'two'
      existing_words = [word1, word2]
      new_words = ['one', 'three']

      result = Pose.get_words_to_remove existing_words, new_words

      result.should eql([word2])
    end

    it 'returns an empty array if there are no words to be removed' do
      word1 = PoseWord.new :text => 'one'
      word2 = PoseWord.new :text => 'two'
      existing_words = [word1, word2]
      new_words = ['one', 'two']

      result = Pose.get_words_to_remove existing_words, new_words

      result.should eql([])
    end
  end

  describe 'get_words_to_add' do

    it 'returns an array with strings that need to be added' do
      word1 = PoseWord.new :text => 'one'
      word2 = PoseWord.new :text => 'two'
      existing_words = [word1, word2]
      new_words = ['one', 'three']

      result = Pose.get_words_to_add existing_words, new_words

      result.should eql(['three'])
    end

    it 'returns an empty array if there is nothing to be added' do
      word1 = PoseWord.new :text => 'one'
      word2 = PoseWord.new :text => 'two'
      existing_words = [word1, word2]
      new_words = ['one', 'two']

      result = Pose.get_words_to_add existing_words, new_words

      result.should eql([])
    end
  end
end
