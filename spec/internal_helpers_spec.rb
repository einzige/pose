# encoding: utf-8

require "spec_helper"

describe Pose::Helpers do

  describe '::get_words_to_add' do
    let(:one) { PoseWord.new(text: 'one') }
    let(:two) { PoseWord.new(text: 'two') }

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
    let(:one) { PoseWord.new(text: 'one') }
    let(:two) { PoseWord.new(text: 'two') }

    it "returns an array of word objects that need to be removed" do
      Pose::Helpers.get_words_to_remove([one, two], %w{one three}).should eql([two])
    end

    it 'returns an empty array if there are no words to be removed' do
      Pose::Helpers.get_words_to_remove([one, two], %w{one two}).should be_empty
    end
  end


  describe 'root_word' do

    it 'converts words into singular' do
      Pose::Helpers.root_word('bars').should eql(['bar'])
    end

    it 'removes special characters' do
      Pose::Helpers.root_word('(bar').should == ['bar']
      Pose::Helpers.root_word('bar)').should == ['bar']
      Pose::Helpers.root_word('(bar)').should == ['bar']
      Pose::Helpers.root_word('>foo').should == ['foo']
      Pose::Helpers.root_word('<foo').should == ['foo']
      Pose::Helpers.root_word('"foo"').should == ['foo']
      Pose::Helpers.root_word('"foo').should == ['foo']
      Pose::Helpers.root_word("'foo'").should == ['foo']
      Pose::Helpers.root_word("'foo's").should == ['foo']
      Pose::Helpers.root_word("foo?").should == ['foo']
      Pose::Helpers.root_word("foo!").should == ['foo']
      Pose::Helpers.root_word("foo/bar").should == ['foo', 'bar']
      Pose::Helpers.root_word("foo-bar").should == ['foo', 'bar']
      Pose::Helpers.root_word("foo--bar").should == ['foo', 'bar']
      Pose::Helpers.root_word("foo.bar").should == ['foo', 'bar']
    end

    it 'removes umlauts' do
      Pose::Helpers.root_word('fünf').should == ['funf']
    end

    it 'splits up numbers' do
      Pose::Helpers.root_word('11.2.2011').should == ['11', '2', '2011']
      Pose::Helpers.root_word('11-2-2011').should == ['11', '2', '2011']
      Pose::Helpers.root_word('30:4-5').should == ['30', '4', '5']
    end

    it 'converts into lowercase' do
      Pose::Helpers.root_word('London').should == ['london']
    end

    it "stores single-letter words" do
      Pose::Helpers.root_word('a b').should == ['a', 'b']
    end

    it "does't encode external URLs" do
      Pose::Helpers.root_word('http://web.com').should == ['http', 'web', 'com']
    end

    it "doesn't store empty words" do
      Pose::Helpers.root_word('  one two  ').should == ['one', 'two']
    end

    it "removes duplicates" do
      Pose::Helpers.root_word('one_one').should == ['one']
      Pose::Helpers.root_word('one one').should == ['one']
    end

    it "splits up complex URLs" do
      Pose::Helpers.root_word('books?id=p7uyWPcVGZsC&dq=closure%20definitive%20guide&pg=PP1#v=onepage&q&f=false').should eql([
        "book", "id", "p7uywpcvgzsc", "dq", "closure", "definitive", "guide", "pg", "pp1", "v", "onepage", "q", "f", "false"])
    end
  end

end

