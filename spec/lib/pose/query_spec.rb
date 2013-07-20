# encoding: utf-8
require "spec_helper"

module Pose

  describe Query do

    let(:subject) { Pose::Query.new [PosableOne, [PosableTwo]], 'query string' }

    describe :initialize do

      it 'flattens the given classes' do
        expect(subject.classes).to eql [PosableOne, PosableTwo]
      end

    end


    describe :class_names do

      it 'returns the names of the given classes' do
        expect(subject.class_names).to eql ['PosableOne', 'PosableTwo']
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

    describe :joins do

      it 'returns the given joins' do
        query = Query.new [], '', joins: [:foo, :bar]
        expect(query.joins).to eql [:foo, :bar]
      end

      it 'returns the given join as an array' do
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
        expect(Pose::Query.new([], 'foo bar').query_words).to eq ['foo', 'bar']
      end

      it 'converts the individual words into their root form' do
        expect(Pose::Query.new([], 'bars').query_words).to eq ['bar']
      end

      it 'splits complex words into separate terms' do
        expect(Pose::Query.new([], 'one-two').query_words).to eq ['one', 'two']
      end

      it 'removes duplicates' do
        expect(Pose::Query.new([], 'foo-bar foo').query_words).to eq ['foo', 'bar']
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
