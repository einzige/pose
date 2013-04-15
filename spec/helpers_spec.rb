# encoding: utf-8
require "spec_helper"

describe Pose::Helpers do

  describe :get_words_to_add do
    let(:one) { Pose::Word.new(text: 'one') }
    let(:two) { Pose::Word.new(text: 'two') }

    context 'having a new word to be added' do
      it 'returns an array with strings that need to be added' do
        expect(Pose::Helpers.get_words_to_add([one, two], %w{one three})).to eql(['three'])
      end
    end

    context 'nothing to add' do
      it 'returns an empty array' do
        expect(Pose::Helpers.get_words_to_add([one, two], %w{one two})).to be_empty
      end
    end
  end


  describe :get_words_to_remove do
    let(:one) { Pose::Word.new(text: 'one') }
    let(:two) { Pose::Word.new(text: 'two') }

    it "returns an array of word objects that need to be removed" do
      expect(Pose::Helpers.get_words_to_remove([one, two], %w{one three})).to eql([two])
    end

    it 'returns an empty array if there are no words to be removed' do
      expect(Pose::Helpers.get_words_to_remove([one, two], %w{one two})).to be_empty
    end
  end


  describe :is_sql_database? do

    it 'recognizes postgres databases' do
      ActiveRecord::Base.connection.class.stub(:name).and_return 'ActiveRecord::ConnectionAdapters::PostgreSQLAdapter'
      expect(Pose::Helpers.is_sql_database?).to be_true
    end

    it 'recognizes sqlite3 databases' do
      ActiveRecord::Base.connection.class.stub(:name).and_return 'ActiveRecord::ConnectionAdapters::SQLite3Adapter'
      expect(Pose::Helpers.is_sql_database?).to be_true
    end
  end

  describe 'is_url?' do

    it 'returns TRUE if the given string is a URL' do
      expect(Pose::Helpers.is_url? 'http://web.com').to be_true
    end

    it 'returns TRUE if the given string is a HTTPS URL' do
      expect(Pose::Helpers.is_url? 'https://web.com').to be_true
    end

    it 'returns FALSE if the given string is not a URL' do
      expect(Pose::Helpers.is_url? 'foo').to be_false
    end

    it 'returns FALSE if the given string is a malformed URL' do
      expect(Pose::Helpers.is_url? 'http://web').to be_false
    end
  end

  describe :make_array do

    it 'converts a single value into an array' do
      expect(Pose::Helpers.make_array(1)).to eq [1]
    end

    it 'leaves arrays as arrays' do
      expect(Pose::Helpers.make_array([1])).to eq [1]
    end

    it 'flattens nested arrays' do
      Pose::Helpers.make_array([1, [2], [[3]]]).should eq [1, 2, 3]
    end
  end


  describe :merge_search_result_word_matches do
    context 'given a new class name' do

      before :each do
        @result = {}
      end

      it 'sets the given ids as the ids for this class name' do
        Pose::Helpers.merge_search_result_word_matches @result, 'class1', [1, 2]
        expect(@result).to eq({ 'class1' => [1, 2] })
      end
    end

    context 'given a class name with already existing ids from another word' do

      before :each do
        @result = { 'class1' => [1, 2] }
      end

      it 'only keeps the ids that are included in both sets' do
        Pose::Helpers.merge_search_result_word_matches @result, 'class1', [1, 3]
        expect(@result).to eq({ 'class1' => [1] })
      end
    end

    context 'with an existing empty result set from a previous query' do

      before :each do
        @result = { 'class1' => [] }
      end

      it 'returns an empty result set' do
        Pose::Helpers.merge_search_result_word_matches @result, 'class1', [1, 3]
        @result.should eq({ 'class1' => [] })
      end
    end

    context 'with a new empty result set' do

      before :each do
        @result = { 'class1' => [1, 2] }
      end

      it 'returns an empty result set' do
        Pose::Helpers.merge_search_result_word_matches @result, 'class1', []
        @result.should eq({ 'class1' => [] })
      end
    end

    context 'with a completely different result set' do

      before :each do
        @result = { 'class1' => [1, 2] }
      end

      it 'returns an empty result set' do
        Pose::Helpers.merge_search_result_word_matches @result, 'class1', [3, 4]
        @result.should eq({ 'class1' => [] })
      end
    end
  end


  describe :search_classes_and_ids_for_word do

    before :each do
      @hit_one_a = create :posable_one, text: 'hit one a'
      @hit_one_b = create :posable_one, text: 'hit one b'
      @miss_one = create :posable_one, text: 'miss one'
      @hit_two = create :posable_two, text: 'hit two'
      @miss_two = create :posable_two, text: 'miss two'
    end

    context 'simple query' do

      it 'returns the matching classes and ids for all given classes' do
        result = Pose::Helpers.search_classes_and_ids_for_word 'hit', ['PosableOne', 'PosableTwo']
        expect(result['PosableOne']).to include @hit_one_a.id
        expect(result['PosableOne']).to include @hit_one_b.id
        expect(result['PosableOne']).to_not include @miss_one.id
        expect(result['PosableTwo']).to include @hit_two.id
        expect(result['PosableTwo']).to_not include @miss_two.id
      end

      it 'does not return matches for classes that are not given' do
        result = Pose::Helpers.search_classes_and_ids_for_word 'hit', ['PosableOne']
        expect(result['PosableOne']).to include @hit_one_a.id
        expect(result['PosableOne']).to include @hit_one_b.id
        expect(result['PosableOne']).to_not include @miss_one.id
        expect(result).to_not have_key 'PosableTwo'
      end
    end

    context 'SQL clauses given' do

      it 'applies the SQL clauses and returns only the matching results' do
        result = Pose::Helpers.search_classes_and_ids_for_word 'hit', ['PosableOne'], { joins: 'INNER JOIN posable_ones ON posable_ones.id=pose_assignments.posable_id and pose_assignments.posable_type="PosableOne"', where: [ 'posable_ones.id = ?', @hit_one_b.id ] }
        expect(result['PosableOne']).to_not include @hit_one_a.id
        expect(result['PosableOne']).to include @hit_one_b.id
      end
    end
  end


  describe :query_terms do

    it 'returns all individual words resulting from the given query' do
      expect(Pose::Helpers.query_terms('foo bar')).to eq ['foo', 'bar']
    end

    it 'converts the individual words into their root form' do
      expect(Pose::Helpers.query_terms('bars')).to eq ['bar']
    end

    it 'splits complex words into separate terms' do
      expect(Pose::Helpers.query_terms('one-two')).to eq ['one', 'two']
    end

    it 'removes duplicates' do
      expect(Pose::Helpers.query_terms('foo-bar foo')).to eq ['foo', 'bar']
    end
  end


  describe :root_word do

    it 'converts words into singular' do
      expect(Pose::Helpers.root_word('bars')).to eql(['bar'])
    end

    it 'removes special characters' do
      expect(Pose::Helpers.root_word('(bar')).to eq ['bar']
      expect(Pose::Helpers.root_word('bar)')).to eq ['bar']
      expect(Pose::Helpers.root_word('(bar)')).to eq ['bar']
      expect(Pose::Helpers.root_word('>foo')).to eq ['foo']
      expect(Pose::Helpers.root_word('<foo')).to eq ['foo']
      expect(Pose::Helpers.root_word('"foo"')).to eq ['foo']
      expect(Pose::Helpers.root_word('"foo')).to eq ['foo']
      expect(Pose::Helpers.root_word("'foo'")).to eq ['foo']
      expect(Pose::Helpers.root_word("'foo's")).to eq ['foo']
      expect(Pose::Helpers.root_word("foo?")).to eq ['foo']
      expect(Pose::Helpers.root_word("foo!")).to eq ['foo']
      expect(Pose::Helpers.root_word("foo/bar")).to eq ['foo', 'bar']
      expect(Pose::Helpers.root_word("foo-bar")).to eq ['foo', 'bar']
      expect(Pose::Helpers.root_word("foo--bar")).to eq ['foo', 'bar']
      expect(Pose::Helpers.root_word("foo.bar")).to eq ['foo', 'bar']
    end

    it 'removes umlauts' do
      expect(Pose::Helpers.root_word('fünf')).to eq ['funf']
    end

    it 'splits up numbers' do
      expect(Pose::Helpers.root_word('11.2.2011')).to eq ['11', '2', '2011']
      expect(Pose::Helpers.root_word('11-2-2011')).to eq ['11', '2', '2011']
      expect(Pose::Helpers.root_word('30:4-5')).to eq ['30', '4', '5']
    end

    it 'converts into lowercase' do
      expect(Pose::Helpers.root_word('London')).to eq ['london']
    end

    it "stores single-letter words" do
      expect(Pose::Helpers.root_word('a b')).to eq ['a', 'b']
    end

    it "does't encode external URLs" do
      expect(Pose::Helpers.root_word('http://web.com')).to eq ['http', 'web', 'com']
    end

    it "doesn't store empty words" do
      expect(Pose::Helpers.root_word('  one two  ')).to eq ['one', 'two']
    end

    it "removes duplicates" do
      expect(Pose::Helpers.root_word('one_one')).to eq ['one']
      expect(Pose::Helpers.root_word('one one')).to eq ['one']
    end

    it "splits up complex URLs" do
      expect(Pose::Helpers.root_word('books?id=p7uyWPcVGZsC&dq=closure%20definitive%20guide&pg=PP1#v=onepage&q&f=false')).to eql([
        "book", "id", "p7uywpcvgzsc", "dq", "closure", "definitive", "guide", "pg", "pp1", "v", "onepage", "q", "f", "false"])
    end
  end


  describe :search_classes_and_ids_for_word do

    it 'returns a hash that contains all the given classes' do
      result = Pose::Helpers.search_classes_and_ids_for_word 'foo', %w{PosableOne PosableTwo}
      expect(result.keys.sort).to eq %w{PosableOne PosableTwo}
    end

    it 'returns the ids of all the posable objects that include the given word' do
      pos1 = PosableOne.create text: 'one two'
      pos2 = PosableTwo.create text: 'one three'
      pos3 = PosableTwo.create text: 'two three'

      result = Pose::Helpers.search_classes_and_ids_for_word 'one', %w{PosableOne PosableTwo}

      expect(result['PosableOne']).to eq [pos1.id]
      expect(result['PosableTwo']).to eq [pos2.id]
    end
  end
end
