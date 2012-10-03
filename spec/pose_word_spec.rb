require 'spec_helper'

describe PoseWord do

  describe 'class methods' do
    subject { PoseWord }

    describe '::remove_unused_words' do
      let(:snippet) { FactoryGirl.create :pose_word }

      before :each do
        snippet and PoseWord.remove_unused_words
      end

      context 'having unused words' do
        its(:count) { should == 0 }
      end

      context 'having used words' do
        let(:snippet) { FactoryGirl.create :posable_one }
        its(:count) { should > 0 }
      end
    end
  end
end
