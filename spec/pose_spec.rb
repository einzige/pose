require "spec_helper"

ActiveRecord::Base.establish_connection(:adapter => "sqlite3", :database => ":memory:")

class PosableOne < ActiveRecord::Base
  posify { [text] }
end

class PosableTwo < ActiveRecord::Base
  posify { [text] }
end

def setup_db
  ActiveRecord::Schema.define(:version => 1) do

    create_table 'posable_ones' do |t|
      t.string 'text'
    end

    create_table 'posable_twos' do |t|
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
  subject { PosableOne.new }

  before :all do
    setup_db
    Pose::CONFIGURATION[:search_in_tests] = true
  end

  after :all do
    teardown_db
    Pose::CONFIGURATION[:search_in_tests] = false
  end
  
  before :each do
    PosableOne.delete_all
    PosableTwo.delete_all
    PoseAssignment.delete_all
    PoseWord.delete_all
  end
  
  describe 'associations' do
    it 'allows to access the associated words of a posable object directly' do
      subject.should have(0).pose_words
      subject.pose_words << PoseWord.new(:text => 'one')
      subject.should have_pose_words(['one'])
    end
  end

  describe 'update_pose_index' do

    context "in the 'test' environment" do
      after :each do
        Pose::CONFIGURATION[:search_in_tests] = true
      end
      
      it "doesn't calls update_pose_words in tests if the test flag is not enabled" do
        Pose::CONFIGURATION[:search_in_tests] = false
        subject.should_not_receive :update_pose_words
        subject.update_pose_index
      end

      it "calls update_pose_words in tests if the test flag is enabled" do
        Pose::CONFIGURATION[:search_in_tests] = true
        subject.should_receive :update_pose_words
        subject.update_pose_index
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
        subject.update_pose_index
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

  describe 'search' do
    
    it 'works' do
      pos1 = PosableOne.create :text => 'one'
      
      result = Pose.search 'one', PosableOne
      
      result.should have(1).items
      result[PosableOne].should have(1).items
      result[PosableOne][0].should == pos1
    end
    
    it 'returns an empty array if nothing matches' do
      pos1 = PosableOne.create :text => 'one'
      
      result = Pose.search 'two', PosableOne
      
      result.should == { PosableOne => [] }
    end
    
    it 'returns all different classes by default' do
      pos1 = PosableOne.create :text => 'foo'
      pos2 = PosableTwo.create :text => 'foo'
      
      result = Pose.search 'foo', [PosableOne, PosableTwo]
      
      result.should have(2).items
      result[PosableOne].should == [pos1]
      result[PosableTwo].should == [pos2]
    end
    
    it 'allows to provide different classes to return' do
      pos1 = PosableOne.create :text => 'foo'
      pos2 = PosableTwo.create :text => 'foo'
      
      result = Pose.search 'foo', [PosableOne, PosableTwo]
      
      result.should have(2).items
      result[PosableOne].should == [pos1]
      result[PosableTwo].should == [pos2]
    end
    
    it 'returns only instances of the given classes' do
      pos1 = PosableOne.create :text => 'one'
      pos2 = PosableTwo.create :text => 'one'
      
      result = Pose.search 'one', PosableOne
      
      result.should have(1).items
      result[PosableOne].should == [pos1]
    end
    
    it 'returns only objects that match all given query words' do
      pos1 = PosableOne.create :text => 'one two'
      pos2 = PosableOne.create :text => 'one three'
      pos3 = PosableOne.create :text => 'two three'
      
      result = Pose.search 'two one', PosableOne
      
      result.should have(1).items
      result[PosableOne].should == [pos1]
    end
    
    it 'returns nothing if searching for a non-existing word' do
      pos1 = PosableOne.create :text => 'one two'
      
      result = Pose.search 'one zonk', PosableOne
      
      result.should have(1).items
      result[PosableOne].should == []
    end
  end
end
