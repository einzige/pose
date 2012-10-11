# encoding: utf-8

require "spec_helper"

describe Pose do
  subject { PosableOne.new }

  describe 'associations' do
    it 'allows to access the associated words of a posable object directly' do
      subject.should have(0).pose_words
      subject.pose_words << PoseWord.new(text: 'one')
      subject.should have_pose_words(['one'])
    end
  end

  describe '#update_pose_index' do

    context "in the 'test' environment" do
      # Set global env configuration.
      before :each do
        Pose::CONFIGURATION[:search_in_tests] = search_in_tests
      end

      # Restores global configuration to default.
      after :each do
        Pose::CONFIGURATION[:search_in_tests] = true
      end

      context "search_in_tests flag is not enabled" do
        let(:search_in_tests) { false }

        it "doesn't call update_pose_words" do
          subject.should_not_receive :update_pose_words
          subject.update_pose_index
        end
      end

      context "search_in_tests flag is enabled" do
        let(:search_in_tests) { true }

        it "calls update_pose_words" do
          subject.should_receive :update_pose_words
          subject.update_pose_index
        end
      end
    end

    context "in the 'production' environment' do" do
      before :each do
        @old_env = Rails.env
        Rails.env = 'production'
        Pose::CONFIGURATION[:search_in_tests] = false
      end

      after :each do
        Rails.env = @old_env
        Pose::CONFIGURATION[:search_in_tests] = true
      end

      it "always calls update_pose_words, even when search_in_tests is disabled" do
        subject.should_receive :update_pose_words
        subject.update_pose_index
      end
    end
  end


  describe '#update_pose_words' do

    it 'saves the words for search' do
      subject.text = 'foo bar'
      subject.update_pose_words
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


  describe 'search' do

    it 'works' do
      pos = PosableOne.create text: 'foo'
      result = Pose.search 'foo', PosableOne
      result.should == { PosableOne => [pos] }
    end

    describe 'classes parameter' do

      before :each do
        @pos1 = PosableOne.create text: 'foo'
        @pos2 = PosableTwo.create text: 'foo'
      end

      it 'returns all requested classes' do
        result = Pose.search 'foo', [PosableOne, PosableTwo]

        result.keys.should have(2).items
        result.keys.should include PosableOne
        result.keys.should include PosableTwo
      end

      it 'returns all matching instances of each requested class' do
        result = Pose.search 'foo', [PosableOne, PosableTwo]

        result[PosableOne].should == [@pos1]
        result[PosableTwo].should == [@pos2]
      end

      it 'returns only instances of the given classes' do
        result = Pose.search 'foo', PosableOne
        result.keys.should include PosableOne
        result.keys.should_not include PosableTwo
      end
    end

    describe 'query parameter' do

      it 'returns an empty array if nothing matches' do
        pos1 = PosableOne.create text: 'one'
        result = Pose.search 'two', PosableOne
        result[PosableOne].should be_empty
      end

      it 'returns only objects that match all given query words' do
        pos1 = PosableOne.create text: 'one two'
        pos2 = PosableOne.create text: 'one three'
        pos3 = PosableOne.create text: 'two three'

        result = Pose.search 'two one', PosableOne

        result[PosableOne].should == [pos1]
      end

      it 'returns nothing if searching for a non-existing word' do
        pos1 = PosableOne.create text: 'one two'
        result = Pose.search 'one zonk', PosableOne
        result[PosableOne].should be_empty
      end

      it 'works if the query is given in uppercase' do
        pos1 = PosableOne.create text: 'one two'
        result = Pose.search 'OnE TwO', PosableOne
        result[PosableOne].should == [pos1]
      end
    end


    describe "'limit' parameter" do

      before :each do
        @pos1 = FactoryGirl.create :posable_one, text: 'foo', private: true
        @pos2 = FactoryGirl.create :posable_one, text: 'foo', private: true
        @pos3 = FactoryGirl.create :posable_one, text: 'foo', private: false
      end

      context 'with ids and no scope' do
        it 'limits the result set to the given number' do
          result = Pose.search 'foo', PosableOne, result_type: :ids, limit: 1
          result[PosableOne].should have(1).item
        end
      end

      context 'with ids and scope' do
        it 'limits the result set to the given number' do
          result = Pose.search 'foo', PosableOne, result_type: :ids, limit: 1, where: [private: false]
          result[PosableOne].should have(1).item
        end
      end

      context 'with classes and no scope' do
        it 'limits the result set to the given number' do
          result = Pose.search 'foo', PosableOne, limit: 1
          result[PosableOne].should have(1).item
        end
      end

      context 'with classes and scope' do
        it 'limits the result set to the given number' do
          result = Pose.search 'foo', PosableOne, limit: 1, where: [private: false]
          result[PosableOne].should have(1).item
        end
      end
    end


    describe "'result_type' parameter" do

      before :each do
        @foo_one = FactoryGirl.create :posable_one, text: 'foo one'
      end

      describe 'default behavior' do
        it 'returns full objects' do
          result = Pose.search 'foo', PosableOne
          result[PosableOne].first.should == @foo_one
        end
      end

      context ':ids given' do
        it 'returns ids instead of objects' do
          result = Pose.search 'foo', PosableOne, result_type: :ids
          result[PosableOne].first.should == @foo_one.id
        end
      end
    end


    describe "'where' parameter" do

      before :each do
        @one = FactoryGirl.create :posable_one, text: 'foo one', private: true
        @bar = FactoryGirl.create :posable_one, text: 'bar one', private: true
        @two = FactoryGirl.create :posable_one, text: 'foo two', private: false
      end

      context 'with result type :classes' do

        it 'limits the result set by the given conditions' do
          result = Pose.search 'foo', PosableOne, where: [ private: true ]
          result[PosableOne].should have(1).item
          result[PosableOne].should include @one
        end

        it 'allows to use the hash syntax for queries' do
          result = Pose.search 'foo', PosableOne, where: [ private: true ]
          result[PosableOne].should have(1).item
          result[PosableOne].should include @one
        end

        it 'allows to use the string syntax for queries' do
          result = Pose.search 'foo', PosableOne, where: [ ['private = ?', true] ]
          result[PosableOne].should have(1).item
          result[PosableOne].should include @one
        end

        it 'allows to combine several conditions' do
          three = FactoryGirl.create :posable_one, text: 'foo two', private: true
          result = Pose.search 'foo', PosableOne, where: [ {private: true}, ['text = ?', 'foo two'] ]
          result[PosableOne].should have(1).item
          result[PosableOne].should include three
        end
      end

      context 'with result type :ids' do

        it 'limits the result set by the given condition' do
          result = Pose.search 'foo', PosableOne, result_type: :ids, where: [ private: true ]
          result[PosableOne].should have(1).item
          result[PosableOne].should include @one.id
        end
      end
    end
  end


  describe 'autocomplete_words' do

    it 'returns words that start with the given phrase' do
      PosableOne.create text: 'great green pine tree'

      result = Pose.autocomplete_words 'gr'

      result.should have(2).words
      result.should include 'great'
      result.should include 'green'
    end

    it 'returns words that match the given phrase exactly' do
      PoseWord.create text: 'cat'
      result = Pose.autocomplete_words 'cat'
      result.should == ['cat']
    end

    it 'stems the search query' do
      PosableOne.create text: 'car'
      result = Pose.autocomplete_words 'cars'
      result.should have(1).words
      result[0].should == 'car'
    end

    it 'returns nothing if the search query is empty' do
      PosableOne.create text: 'foo bar'
      result = Pose.autocomplete_words ''
      result.should be_empty
    end
  end
end
