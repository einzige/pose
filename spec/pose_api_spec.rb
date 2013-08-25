# encoding: utf-8

require "spec_helper"

module Pose
  describe Pose do
    subject { PosableOne.new }

    describe 'associations' do
      it 'allows to access the associated words of a posable object directly' do
        expect(subject).to have(0).pose_words
        subject.pose_words << Word.new(text: 'one')
        expect(subject).to have_pose_words 'one'
      end
    end


    describe :update_pose_index do

      before :each do
        Pose::CONFIGURATION[:perform_search] = perform_search
      end

      after :each do
        Pose::CONFIGURATION.delete :perform_search
      end

      context "search_in_tests flag is not enabled" do
        let(:perform_search) { false }

        it "doesn't call update_pose_words" do
          subject.should_not_receive :update_pose_words
          subject.update_pose_index
        end
      end

      context "search_in_tests flag is enabled" do
        let(:perform_search) { true }

        it "calls update_pose_words" do
          subject.should_receive :update_pose_words
          subject.update_pose_index
        end
      end
    end


    describe :update_pose_words do

      it 'saves the words for search' do
        subject.text = 'foo bar'
        subject.update_pose_words
        expect(subject).to have_pose_words 'foo', 'bar'
      end

      it 'updates the search index when the text is changed' do
        subject.text = 'foo'
        subject.save!

        subject.text = 'other text'
        subject.update_pose_words

        expect(subject).to have_pose_words 'other', 'text'
      end

      it "doesn't create duplicate words" do
        subject.text = 'foo foo'
        subject.save!
        expect(subject).to have(1).pose_words
      end
    end


    describe :search do

      it 'works' do
        pos = PosableOne.create text: 'foo'
        result = Pose.search 'foo', PosableOne
        expect(result).to eq({ PosableOne => [pos] })
      end

      describe 'classes parameter' do

        before :each do
          @pos1 = PosableOne.create text: 'foo'
          @pos2 = PosableTwo.create text: 'foo'
        end

        it 'returns all requested classes' do
          result = Pose.search 'foo', [PosableOne, PosableTwo]

          expect(result.keys).to have(2).items
          expect(result.keys).to include PosableOne
          expect(result.keys).to include PosableTwo
        end

        it 'returns all matching instances of each requested class' do
          result = Pose.search 'foo', [PosableOne, PosableTwo]

          expect(result[PosableOne]).to eq [@pos1]
          expect(result[PosableTwo]).to eq [@pos2]
        end

        it 'returns only instances of the given classes' do
          result = Pose.search 'foo', PosableOne
          expect(result.keys).to include PosableOne
          result.keys.should_not include PosableTwo
        end
      end

      describe 'query parameter' do

        it 'returns an empty array if nothing matches' do
          pos1 = PosableOne.create text: 'one'
          result = Pose.search 'two', PosableOne
          expect(result[PosableOne]).to be_empty
        end

        it 'returns only objects that match all given query words' do
          pos1 = PosableOne.create text: 'one two'
          pos2 = PosableOne.create text: 'one three'
          pos3 = PosableOne.create text: 'two three'

          result = Pose.search 'two one', PosableOne

          expect(result[PosableOne]).to eq [pos1]
        end

        it 'returns nothing if searching for a non-existing word' do
          pos1 = PosableOne.create text: 'one two'
          result = Pose.search 'one zonk', PosableOne
          expect(result[PosableOne]).to be_empty
        end

        it 'works if the query is given in uppercase' do
          pos1 = PosableOne.create text: 'one two'
          result = Pose.search 'OnE TwO', PosableOne
          expect(result[PosableOne]).to eq [pos1]
        end
      end


      describe "'limit' parameter" do

        before :each do
          @pos1 = create :posable_one, text: 'foo', private: true
          @pos2 = create :posable_one, text: 'foo', private: true
          @pos3 = create :posable_one, text: 'foo', private: false
        end

        context 'with ids and no scope' do
          it 'limits the result set to the given number' do
            result = Pose.search 'foo', PosableOne, result_type: :ids, limit: 1
            expect(result[PosableOne]).to have(1).item
          end
        end

        context 'with ids and scope' do
          it 'limits the result set to the given number' do
            result = Pose.search 'foo',
                                 PosableOne,
                                 result_type: :ids,
                                 limit: 1,
                                 joins: PosableOne,
                                 where: ["posable_ones.private = ?", false]
            expect(result[PosableOne]).to have(1).item
          end
        end

        context 'with classes and no scope' do
          it 'limits the result set to the given number' do
            result = Pose.search 'foo',
                                 PosableOne,
                                 limit: 1
            expect(result[PosableOne]).to have(1).item
          end
        end

        context 'with classes and scope' do
          it 'limits the result set to the given number' do
            result = Pose.search 'foo',
                                 PosableOne,
                                 limit: 1,
                                 joins: PosableOne,
                                 where: ["posable_ones.private = ?", false]
            expect(result[PosableOne]).to have(1).item
            expect(result[PosableOne]).to eq [@pos3]
          end
        end
      end


      describe "'result_type' parameter" do

        before :each do
          @foo_one = create :posable_one, text: 'foo one'
        end

        describe 'default behavior' do
          it 'returns full objects' do
            result = Pose.search 'foo', PosableOne
            expect(result[PosableOne].first).to eq @foo_one
          end
        end

        context ':ids given' do
          it 'returns ids instead of objects' do
            result = Pose.search 'foo', PosableOne, result_type: :ids
            expect(result[PosableOne].first).to eq @foo_one.id
          end
        end
      end


      describe "'where' parameter" do

        before :each do
          @one = create :posable_one, text: 'foo one', private: true
          @bar = create :posable_one, text: 'bar one', private: true
          @two = create :posable_one, text: 'foo two', private: false
        end

        context 'with result type :classes' do

          it 'limits the result set by the given conditions' do
            result = Pose.search 'foo',
                                 PosableOne,
                                 joins: PosableOne,
                                 where: ["posable_ones.private = ?", true]
            expect(result[PosableOne]).to have(1).item
            expect(result[PosableOne]).to include @one
          end

          it 'allows to use the string syntax for queries' do
            result = Pose.search 'foo',
                                 PosableOne,
                                 joins: PosableOne,
                                 where: ["posable_ones.private = ?", true]
            expect(result[PosableOne]).to have(1).item
            expect(result[PosableOne]).to include @one
          end

          it 'allows to combine several conditions' do
            three = create :posable_one, text: 'foo two', private: true
            result = Pose.search 'foo',
                                 PosableOne,
                                 joins: PosableOne,
                                 where: [ ["posable_ones.private = ?", true],
                                          ['posable_ones.text = ?', 'foo two'] ]
            expect(result[PosableOne]).to have(1).item
            expect(result[PosableOne]).to include three
          end
        end

        context 'with result type :ids' do

          it 'limits the result set by the given condition' do
            result = Pose.search 'foo',
                                 PosableOne,
                                 result_type: :ids,
                                 joins: PosableOne,
                                 where: ["posable_ones.private = ?", true]
            expect(result[PosableOne]).to have(1).item
            expect(result[PosableOne]).to include @one.id
          end
        end
      end

      describe ':joins parameter' do

        before :each do
          @user_1 = create :user, name: 'Jeff'
          @user_2 = create :user, name: 'Jim'
          @one = create :posable_one, text: 'snippet one', user: @user_1
          @two = create :posable_one, text: 'snippet two', user: @user_2
        end

        it 'allows to use joined tables for queries' do
          result = Pose.search 'snippet',
                               PosableOne,
                               { joins: [ PosableOne,
                                          "INNER JOIN users on posable_ones.user_id=users.id" ],
                                 where: ["users.name = 'Jeff'"] }
          expect(result[PosableOne].map(&:text)).to eql ['snippet one']
        end

        it 'allows to load data from joined tables'
      end
    end


    describe :autocomplete_words do

      it 'returns words that start with the given phrase' do
        PosableOne.create text: 'great green pine tree'

        result = Pose.autocomplete_words 'gr'

        expect(result).to have(2).words
        expect(result).to include 'great'
        expect(result).to include 'green'
      end

      it 'returns words that match the given phrase exactly' do
        Word.create text: 'cat'
        result = Pose.autocomplete_words 'cat'
        expect(result).to eq ['cat']
      end

      it 'stems the search query' do
        PosableOne.create text: 'car'
        result = Pose.autocomplete_words 'cars'
        expect(result).to have(1).words
        expect(result[0]).to eq 'car'
      end

      it 'returns nothing if the search query is empty' do
        PosableOne.create text: 'foo bar'
        result = Pose.autocomplete_words ''
        expect(result).to be_empty
      end
    end

    describe "::has_sql_connection?" do

      it 'recognizes postgres databases' do
        ActiveRecord::Base.connection.class.stub(:name).and_return 'ActiveRecord::ConnectionAdapters::PostgreSQLAdapter'
        expect(Pose.has_sql_connection?).to be_true
      end

      it 'recognizes sqlite3 databases' do
        ActiveRecord::Base.connection.class.stub(:name).and_return 'ActiveRecord::ConnectionAdapters::SQLite3Adapter'
        expect(Pose.has_sql_connection?).to be_true
      end
    end
  end
end
