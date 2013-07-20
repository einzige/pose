require "spec_helper"

describe Pose::Search do

  let(:subject) { Pose::Search.new [PosableOne, [PosableTwo]], 'query string' }

  describe :merge_search_result_word_matches do
    context 'given a new class name' do

      before :each do
        @result = {}
      end

      it 'sets the given ids as the ids for this class name' do
        subject.merge_search_result_word_matches @result, 'class1', [1, 2]
        expect(@result).to eq({ 'class1' => [1, 2] })
      end
    end

    context 'given a class name with already existing ids from another word' do

      before :each do
        @result = { 'class1' => [1, 2] }
      end

      it 'only keeps the ids that are included in both sets' do
        subject.merge_search_result_word_matches @result, 'class1', [1, 3]
        expect(@result).to eq({ 'class1' => [1] })
      end
    end

    context 'with an existing empty result set from a previous query' do

      before :each do
        @result = { 'class1' => [] }
      end

      it 'returns an empty result set' do
        subject.merge_search_result_word_matches @result, 'class1', [1, 3]
        @result.should eq({ 'class1' => [] })
      end
    end

    context 'with a new empty result set' do

      before :each do
        @result = { 'class1' => [1, 2] }
      end

      it 'returns an empty result set' do
        subject.merge_search_result_word_matches @result, 'class1', []
        @result.should eq({ 'class1' => [] })
      end
    end

    context 'with a completely different result set' do

      before :each do
        @result = { 'class1' => [1, 2] }
      end

      it 'returns an empty result set' do
        subject.merge_search_result_word_matches @result, 'class1', [3, 4]
        @result.should eq({ 'class1' => [] })
      end
    end
  end
end
