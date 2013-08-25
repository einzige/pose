# encoding: utf-8
require "spec_helper"

module Pose
  describe Query do
    let(:subject) { Query.new [PosableOne, [PosableTwo]], 'query string' }


    describe :initialize do

      it 'flattens the given classes' do
        expect(subject.classes).to eql [PosableOne, PosableTwo]
      end
    end


    describe :class_names do

      it 'returns the names of the given classes' do
        expect(subject.class_names).to eql %w[PosableOne PosableTwo]
      end
    end


    describe :has_joins? do

      it 'returns TRUE if the query has joins' do
        query = Query.new [], '', joins: :user
        expect(query).to have_joins
      end

      it 'returns FALSE if the query has no joins' do
        query = Query.new [], ''
        expect(query).to_not have_joins
      end
    end


    describe 'is_url?' do

      it 'returns TRUE if the given string is a URL' do
        expect(Query.is_url? 'http://web.com').to be_true
      end

      it 'returns TRUE if the given string is localhost' do
        expect(Query.is_url? 'http://localhost').to be_true
      end

      it 'returns TRUE if localhost has a port' do
        expect(Query.is_url? 'http://localhost:3000').to be_true
      end

      it 'returns TRUE if the given url has a port' do
        expect(Query.is_url? 'http://web.com:8080').to be_true
      end

      it 'returns TRUE if the given string is a HTTPS URL' do
        expect(Query.is_url? 'https://web.com').to be_true
      end

      it 'returns FALSE if the given string is not a URL' do
        expect(Query.is_url? 'foo').to be_false
      end

      it 'returns FALSE if the given string is a malformed URL' do
        expect(Query.is_url? 'http://web').to be_false
      end
    end


    describe :joins do

      it 'returns the given joins' do
        query = Query.new [], '', joins: [:foo, :bar]
        expect(query.joins).to eql [:foo, :bar]
      end

      it 'returns a single given join as an array' do
        query = Query.new [], '', joins: :foo
        expect(query.joins).to eql [:foo]
      end

      it 'returns an empty array if no joins are given' do
        query = Query.new [], ''
        expect(query.joins).to eql []
      end
    end


    describe :query_words do

      it 'returns all individual words resulting from the given query' do
        expect(Query.new([], 'foo bar').query_words).to eq ['foo', 'bar']
      end

      it 'converts the individual words into their root form' do
        expect(Query.new([], 'bars').query_words).to eq ['bar']
      end

      it 'splits complex words into separate terms' do
        expect(Query.new([], 'one-two').query_words).to eq ['one', 'two']
      end

      it 'removes duplicates' do
        expect(Query.new([], 'foo-bar foo').query_words).to eq ['foo', 'bar']
      end
    end


    describe :root_word do

      it 'converts words into singular' do
        expect(Query.root_word('bars')).to eql(['bar'])
      end

      it 'removes special characters' do
        expect(Query.root_word('(bar')).to eq ['bar']
        expect(Query.root_word('bar)')).to eq ['bar']
        expect(Query.root_word('(bar)')).to eq ['bar']
        expect(Query.root_word('>foo')).to eq ['foo']
        expect(Query.root_word('<foo')).to eq ['foo']
        expect(Query.root_word('"foo"')).to eq ['foo']
        expect(Query.root_word('"foo')).to eq ['foo']
        expect(Query.root_word("'foo'")).to eq ['foo']
        expect(Query.root_word("'foo's")).to eq ['foo']
        expect(Query.root_word("foo?")).to eq ['foo']
        expect(Query.root_word("foo!")).to eq ['foo']
        expect(Query.root_word("foo/bar")).to eq ['foo', 'bar']
        expect(Query.root_word("foo-bar")).to eq ['foo', 'bar']
        expect(Query.root_word("foo--bar")).to eq ['foo', 'bar']
        expect(Query.root_word("foo.bar")).to eq ['foo', 'bar']
      end

      it 'removes umlauts' do
        expect(Query.root_word('fünf')).to eq ['funf']
      end

      it 'splits up numbers' do
        expect(Query.root_word('11.2.2011')).to eq ['11', '2', '2011']
        expect(Query.root_word('11-2-2011')).to eq ['11', '2', '2011']
        expect(Query.root_word('30:4-5')).to eq ['30', '4', '5']
      end

      it 'converts into lowercase' do
        expect(Query.root_word('London')).to eq ['london']
      end

      it "stores single-letter words" do
        expect(Query.root_word('a b')).to eq ['a', 'b']
      end

      it "does't encode external URLs" do
        expect(Query.root_word('http://web.com')).to eq ['http', 'web', 'com']
      end

      it "doesn't store empty words" do
        expect(Query.root_word('  one two  ')).to eq ['one', 'two']
      end

      it "removes duplicates" do
        expect(Query.root_word('one_one')).to eq ['one']
        expect(Query.root_word('one one')).to eq ['one']
      end

      it "splits up complex URLs" do
        expect(Query.root_word('books?id=p7uyWPcVGZsC&dq=closure%20definitive%20guide&pg=PP1#v=onepage&q&f=false')).to eql([
          "book", "id", "p7uywpcvgzsc", "dq", "closure", "definitive", "guide", "pg", "pp1", "v", "onepage", "q", "f", "false"])
      end
    end


    describe :where do

      it 'returns the given simple WHERE clause as an iterable array' do
        query = Query.new [], '', where: ['foo = ?', false]
        expect(query.where).to eq [['foo = ?', false]]
      end

      it 'returns the given multiple WHERE clauses as given' do
        query = Query.new [], '', where: [ ['foo = ?', false], ['bar = ?', true] ]
        expect(query.where).to eq [ ['foo = ?', false], ['bar = ?', true] ]
      end

      it 'returns the given multiple string WHERE clauses as given' do
        query = Query.new [], '', where: [ ['foo = 1'], ['bar = 2'] ]
        expect(query.where).to eq [ ['foo = 1'], ['bar = 2'] ]
      end

      it 'returns an empty array if no where clause is given' do
        query = Query.new [], ''
        expect(query.where).to eq []
      end

      it 'returns the given hash clause as it is given' do
        query = Query.new [], '', where: { foo: 'foo' }
        expect(query.where).to eql({ foo: 'foo' })
      end

      it 'returns multiple hash clauses as given' do
        query = Query.new [], '', where: [{ foo: 'foo' }, { bar: 'bar' }]
        expect(query.where).to eql [{ foo: 'foo' }, {bar: 'bar'}]
      end
    end
  end
end
