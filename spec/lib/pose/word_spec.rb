require 'spec_helper'

module Pose
  describe Word do

    describe "::factory" do

      context 'given a non-existing word' do
        it 'creates the word in the database' do
          expect(Word).to have(0).instances
          Word.factory ['one']
          expect(Word.pluck :text).to eql %w[ one ]
        end
      end

      context 'existing word' do
        before do
          Word.create text: 'one'
          @words = Word.factory ['one']
        end

        it 'returns the word' do
          expect(@words.map &:text).to eql %w[one]
        end

        it 'does not create a new Word in the database' do
          expect(Word).to have(1).instance
        end
      end
    end


    describe 'class methods' do

      shared_examples 'cleans unused words' do
        it 'removes unused words' do
          create :word
          Word.remove_unused_words
          expect(Word.count).to eql 0
        end

        it 'does not remove used words' do
          create :posable_one
          Word.remove_unused_words
          expect(Word.count).to be > 0
        end
      end

      context 'with a SQL database' do
        before :each do
          # TODO: do not mock class method
          Pose.should_receive(:has_sql_connection?).and_return(true)
        end

        it_should_behave_like 'cleans unused words'
      end

      context 'without a SQL database' do
        before :each do
          # TODO: do not mock class method
          Pose.should_receive(:has_sql_connection?).and_return(false)
        end

        it_should_behave_like 'cleans unused words'
      end
    end
  end
end
