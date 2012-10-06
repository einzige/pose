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

    # TODO(REMOVE).
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

  describe '::get_words_to_remove' do
    let(:one) { PoseWord.new(text: 'one') }
    let(:two) { PoseWord.new(text: 'two') }

    it "returns an array of word objects that need to be removed" do
      Pose.get_words_to_remove([one, two], %w{one three}).should eql([two])
    end

    it 'returns an empty array if there are no words to be removed' do
      Pose.get_words_to_remove([one, two], %w{one two}).should be_empty
    end
  end

  describe '::get_words_to_add' do
    let(:one) { PoseWord.new(text: 'one') }
    let(:two) { PoseWord.new(text: 'two') }

    context 'having a new word to be added' do
      it 'returns an array with strings that need to be added' do
        Pose.get_words_to_add([one, two], %w{one three}).should eql(['three'])
      end
    end

    context 'nothing to add' do
      it 'returns an empty array' do
        Pose.get_words_to_add([one, two], %w{one two}).should be_empty
      end
    end
  end

  describe 'root_word' do

    it 'converts words into singular' do
      Pose.root_word('bars').should eql(['bar'])
    end

    it 'removes special characters' do
      Pose.root_word('(bar').should == ['bar']
      Pose.root_word('bar)').should == ['bar']
      Pose.root_word('(bar)').should == ['bar']
      Pose.root_word('>foo').should == ['foo']
      Pose.root_word('<foo').should == ['foo']
      Pose.root_word('"foo"').should == ['foo']
      Pose.root_word('"foo').should == ['foo']
      Pose.root_word("'foo'").should == ['foo']
      Pose.root_word("'foo's").should == ['foo']
      Pose.root_word("foo?").should == ['foo']
      Pose.root_word("foo!").should == ['foo']
      Pose.root_word("foo/bar").should == ['foo', 'bar']
      Pose.root_word("foo-bar").should == ['foo', 'bar']
      Pose.root_word("foo--bar").should == ['foo', 'bar']
      Pose.root_word("foo.bar").should == ['foo', 'bar']
    end

    it 'removes umlauts' do
      Pose.root_word('fünf').should == ['funf']
    end

    it 'splits up numbers' do
      Pose.root_word('11.2.2011').should == ['11', '2', '2011']
      Pose.root_word('11-2-2011').should == ['11', '2', '2011']
      Pose.root_word('30:4-5').should == ['30', '4', '5']
    end

    it 'converts into lowercase' do
      Pose.root_word('London').should == ['london']
    end

    it "stores single-letter words" do
      Pose.root_word('a b').should == ['a', 'b']
    end

    it "does't encode external URLs" do
      Pose.root_word('http://web.com').should == ['http', 'web', 'com']
    end

    it "doesn't store empty words" do
      Pose.root_word('  one two  ').should == ['one', 'two']
    end

    it "removes duplicates" do
      Pose.root_word('one_one').should == ['one']
      Pose.root_word('one one').should == ['one']
    end

    it "splits up complex URLs" do
      Pose.root_word('books?id=p7uyWPcVGZsC&dq=closure%20definitive%20guide&pg=PP1#v=onepage&q&f=false').should eql([
        "book", "id", "p7uywpcvgzsc", "dq", "closure", "definitive", "guide", "pg", "pp1", "v", "onepage", "q", "f", "false"])
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

      it 'works' do
        FactoryGirl.create :posable_one, text: 'foo one'
        FactoryGirl.create :posable_one, text: 'foo two'
        FactoryGirl.create :posable_one, text: 'foo three'

        result = Pose.search 'foo', PosableOne, limit: 2

        result[PosableOne].should have(2).items
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


    describe "'scopes' parameter" do

      before :each do
        @one = FactoryGirl.create :posable_one, text: 'foo one', private: true
        @two = FactoryGirl.create :posable_one, text: 'foo two', private: false
      end

      context 'with result type :classes' do

        it 'limits the result set by the given scope' do
          result = Pose.search 'foo', PosableOne, scope: [ private: true ]
          result[PosableOne].should have(1).item
          result[PosableOne].should include @one
        end

        it 'allows to use the hash syntax for queries' do
          result = Pose.search 'foo', PosableOne, scope: [ private: true ]
          result[PosableOne].should have(1).item
          result[PosableOne].should include @one
        end

        it 'allows to use the string syntax for queries' do
          result = Pose.search 'foo', PosableOne, scope: [ ['private = ?', true] ]
          result[PosableOne].should have(1).item
          result[PosableOne].should include @one
        end

        it 'allows to combine several scopes' do
          @three = FactoryGirl.create :posable_one, text: 'foo two', private: true
          result = Pose.search 'foo', PosableOne, scope: [ {private: true}, ['text = ?', 'foo two'] ]
          result[PosableOne].should have(1).item
          result[PosableOne].should include @three
        end
      end

      context 'with result type :ids' do

        it 'limits the result set by the given scope' do
          result = Pose.search 'foo', PosableOne, result_type: :ids, scope: [ private: true ]
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
