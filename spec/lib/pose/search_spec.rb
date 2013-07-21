require "spec_helper"

module Pose

  describe Search do
    let(:subject) { Search.new [PosableOne, [PosableTwo]], 'query string' }
    let(:arel) { stub() }
    let(:arel_2) { stub() }
    let(:arel_3) { stub() }


    describe :add_join do

      it 'returns the new arel' do
        arel.should_receive(:joins).with('foo').and_return(arel_2)
        expect(subject.add_join arel, 'foo').to eql arel_2
      end

      context 'given a class' do
        it 'adds a join from PoseAssignment to the given class' do
          arel.should_receive(:joins)
              .with "INNER JOIN posable_ones ON pose_assignments.posable_id=posable_ones.id AND pose_assignments.posable_type='PosableOne'"
          subject.add_join arel, PosableOne
        end
      end

      context 'given a string' do
        it 'applies the join as given' do
          arel.should_receive(:joins).with "join string"
          subject.add_join arel, 'join string'
        end
      end

      context 'given a symbol' do
        it 'applies the join as given' do
          arel.should_receive(:joins).with :association
          subject.add_join arel, :association
        end
      end
    end


    describe :add_joins do

      it 'adds all joins to the given arel' do
        arel.should_receive(:joins).with('one').and_return(arel_2)
        arel_2.should_receive(:joins).with('two').and_return(arel_3)
        search = Search.new [], '', joins: ['one', 'two']
        search.add_joins arel
      end

      it 'returns the given arel' do
        arel.should_receive(:joins).and_return(arel_2)
        arel_2.should_receive(:joins).and_return(arel_3)
        search = Search.new [], '', joins: ['one', 'two']
        expect(search.add_joins arel).to eql arel_3
      end
    end


    describe :add_wheres do

      it 'adds all joins to the given arel' do
        arel.should_receive(:where).with(['one = ?', true]).and_return(arel_2)
        arel_2.should_receive(:where).with(['two = ?', false]).and_return(arel_3)
        search = Search.new [], '', where: [['one = ?', true], ['two = ?', false]]
        search.add_wheres arel
      end

      it 'returns the given arel' do
        arel.should_receive(:where).and_return(arel_2)
        arel_2.should_receive(:where).and_return(arel_3)
        search = Search.new [], '', where: [['one'], ['two']]
        expect(search.add_wheres arel).to eql arel_3
      end
    end


    describe :empty_result do

      it 'returns a hash with classes and empty arrays for each class in the search query' do
        search = Search.new [PosableOne, PosableTwo], ''
        result = search.empty_result
        expect(result['PosableOne']).to eq []
        expect(result['PosableTwo']).to eq []
        expect(result).to_not have_key 'User'
      end
    end


    describe :limit_ids do
      before :each do
        @search = Search.new PosableOne, '', limit: 2
      end

      context 'with empty id set' do
        it 'does nothing' do
          result = { PosableOne => [] }
          @search.limit_ids result
          expect(result[PosableOne]).to eql []
        end
      end

      context 'with id set less than the given limit' do
        it 'does nothing' do
          result = { PosableOne => [1, 2] }
          @search.limit_ids result
          expect(result[PosableOne]).to eql [1, 2]
        end
      end

      context 'with id set longer than the given limit' do
        it 'truncates the id set' do
          result = { PosableOne => [1, 2, 3] }
          @search.limit_ids result
          expect(result[PosableOne]).to eql [1, 2]
        end
      end

      context 'without limit in query' do
        it 'does nothing' do
          @search = Search.new PosableOne, ''
          result = { PosableOne => [1, 2, 3] }
          @search.limit_ids result
          expect(result[PosableOne]).to eql [1, 2, 3]
        end
      end
    end


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
end
