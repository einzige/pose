# encoding: utf-8
require "spec_helper"

describe Pose::Helpers do

  describe '::get_words_to_add' do
    let(:one) { Pose::Word.new(text: 'one') }
    let(:two) { Pose::Word.new(text: 'two') }

    context 'having a new word to be added' do
      it 'returns an array with strings that need to be added' do
        Pose::Helpers.get_words_to_add([one, two], %w{one three}).should eql(['three'])
      end
    end

    context 'nothing to add' do
      it 'returns an empty array' do
        Pose::Helpers.get_words_to_add([one, two], %w{one two}).should be_empty
      end
    end
  end


  describe '::get_words_to_remove' do
    let(:one) { Pose::Word.new(text: 'one') }
    let(:two) { Pose::Word.new(text: 'two') }

    it "returns an array of word objects that need to be removed" do
      Pose::Helpers.get_words_to_remove([one, two], %w{one three}).should eql([two])
    end

    it 'returns an empty array if there are no words to be removed' do
      Pose::Helpers.get_words_to_remove([one, two], %w{one two}).should be_empty
    end
  end


  describe 'make_array' do

    it 'converts a single value into an array' do
      Pose::Helpers.make_array(1).should eq [1]
    end

    it 'leaves arrays as arrays' do
      Pose::Helpers.make_array([1]).should eq [1]
    end
  end


  describe 'merge_search_result_word_matches' do
    context 'given a new class name' do

      before :each do
        @result = {}
      end

      it 'sets the given ids as the ids for this class name' do
        Pose::Helpers.merge_search_result_word_matches @result, 'class1', [1, 2]
        @result.should eq({ 'class1' => [1, 2] })
      end
    end

    context 'given a class name with already existing ids from another word' do

      before :each do
        @result = { 'class1' => [1, 2] }
      end

      it 'only keeps the ids that are included in both sets' do
        Pose::Helpers.merge_search_result_word_matches @result, 'class1', [1, 3]
        @result.should eq({ 'class1' => [1] })
      end
    end
  end


  describe 'query_terms' do
    it 'returns all individual words resulting from the given query' do
      Pose::Helpers.query_terms('foo bar').should eq ['foo', 'bar']
    end

    it 'converts the individual words into their root form' do
      Pose::Helpers.query_terms('bars').should eq ['bar']
    end

    it 'splits complex words into separate terms' do
      Pose::Helpers.query_terms('one-two').should eq ['one', 'two']
    end

    it 'removes duplicates' do
      Pose::Helpers.query_terms('foo-bar foo').should eq ['foo', 'bar']
    end
  end


  describe 'root_word' do

    it 'converts words into singular' do
      Pose::Helpers.root_word('bars').should eql(['bar'])
    end

    it 'removes special characters' do
      Pose::Helpers.root_word('(bar').should eq ['bar']
      Pose::Helpers.root_word('bar)').should eq ['bar']
      Pose::Helpers.root_word('(bar)').should eq ['bar']
      Pose::Helpers.root_word('>foo').should eq ['foo']
      Pose::Helpers.root_word('<foo').should eq ['foo']
      Pose::Helpers.root_word('"foo"').should eq ['foo']
      Pose::Helpers.root_word('"foo').should eq ['foo']
      Pose::Helpers.root_word("'foo'").should eq ['foo']
      Pose::Helpers.root_word("'foo's").should eq ['foo']
      Pose::Helpers.root_word("foo?").should eq ['foo']
      Pose::Helpers.root_word("foo!").should eq ['foo']
      Pose::Helpers.root_word("foo/bar").should eq ['foo', 'bar']
      Pose::Helpers.root_word("foo-bar").should eq ['foo', 'bar']
      Pose::Helpers.root_word("foo--bar").should eq ['foo', 'bar']
      Pose::Helpers.root_word("foo.bar").should eq ['foo', 'bar']
    end

    it 'removes umlauts' do
      Pose::Helpers.root_word('fünf').should eq ['funf']
    end

    it 'splits up numbers' do
      Pose::Helpers.root_word('11.2.2011').should eq ['11', '2', '2011']
      Pose::Helpers.root_word('11-2-2011').should eq ['11', '2', '2011']
      Pose::Helpers.root_word('30:4-5').should eq ['30', '4', '5']
    end

    it 'converts into lowercase' do
      Pose::Helpers.root_word('London').should eq ['london']
    end

    it "stores single-letter words" do
      Pose::Helpers.root_word('a b').should eq ['a', 'b']
    end

    it "does't encode external URLs" do
      Pose::Helpers.root_word('http://web.com').should eq ['http', 'web', 'com']
    end

    it "doesn't store empty words" do
      Pose::Helpers.root_word('  one two  ').should eq ['one', 'two']
    end

    it "removes duplicates" do
      Pose::Helpers.root_word('one_one').should eq ['one']
      Pose::Helpers.root_word('one one').should eq ['one']
    end

    it "splits up complex URLs" do
      Pose::Helpers.root_word('books?id=p7uyWPcVGZsC&dq=closure%20definitive%20guide&pg=PP1#v=onepage&q&f=false').should eql([
        "book", "id", "p7uywpcvgzsc", "dq", "closure", "definitive", "guide", "pg", "pp1", "v", "onepage", "q", "f", "false"])
    end
  end


  describe 'search_classes_and_ids_for_word' do

    it 'returns a hash that contains all the given classes' do
      result = Pose::Helpers.search_classes_and_ids_for_word 'foo', %w{PosableOne PosableTwo}
      result.keys.sort.should eq %w{PosableOne PosableTwo}
    end

    it 'returns the ids of all the posable objects that include the given word' do
      pos1 = PosableOne.create text: 'one two'
      pos2 = PosableTwo.create text: 'one three'
      pos3 = PosableTwo.create text: 'two three'

      result = Pose::Helpers.search_classes_and_ids_for_word 'one', %w{PosableOne PosableTwo}

      result['PosableOne'].should eq [pos1.id]
      result['PosableTwo'].should eq [pos2.id]
    end
  end
end
