require 'spec_helper'

module Pose
  describe Word do

    describe 'class methods' do

      describe :remove_unused_words do

        shared_examples 'it properly removes unused words' do
          it 'removes unused words' do
            FactoryGirl.create :word
            Word.remove_unused_words
            expect(Word.count).to eql 0
          end

          it 'does not remove used words' do
            FactoryGirl.create :posable_one
            Word.remove_unused_words
            expect(Word.count).to be > 0
          end
        end
      end

      context 'with a SQL database' do
        before :each do
          Helpers.should_receive(:is_sql_database?).and_return(true)
        end

        it_should_behave_like 'it properly removes unused words'
      end

      context 'without a SQL database' do
        before :each do
          Helpers.should_receive(:is_sql_database?).and_return(false)
        end

        it_should_behave_like 'it properly removes unused words'
      end
    end
  end
end
