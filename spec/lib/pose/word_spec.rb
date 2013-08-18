require 'spec_helper'

module Pose
  describe Word do
    describe "::factory" do
      let(:words) { ['1'] }

      subject { described_class.factory(words) }

      context "new word passed" do
        it 'creates words' do
          subject.should have(1).word
          subject.first.text.should == '1'
        end
      end

      context "existing word" do
        before do
          Word.create(text: '1')
        end

        it { expect { subject }.not_to change { Word.count } }
        it { should == [Word.first] }
      end
    end

    describe 'class methods' do

      shared_examples 'cleans unused words' do
        it 'removes unused words' do
          create :word
          Pose::Word.remove_unused_words
          expect(Pose::Word.count).to eql 0
        end

        it 'does not remove used words' do
          create :posable_one
          Pose::Word.remove_unused_words
          expect(Pose::Word.count).to be > 0
        end
      end

      context 'with a SQL database' do
        before :each do
          Helpers.should_receive(:is_sql_database?).and_return(true)
        end

        it_should_behave_like 'cleans unused words'
      end

      context 'without a SQL database' do
        before :each do
          Helpers.should_receive(:is_sql_database?).and_return(false)
        end

        it_should_behave_like 'cleans unused words'
      end
    end
  end
end
