require 'spec_helper'

describe PoseWord do

  describe 'class methods' do
    subject { PoseWord }

    describe '::remove_unused_words' do

      before :each do
        instantiate_objects
        PoseWord.remove_unused_words
      end

      context 'having unused words' do
        let(:instantiate_objects) { FactoryGirl.create :pose_word }
        its(:count) { should == 0 }
      end

      context 'having used words' do
        let(:instantiate_objects) { FactoryGirl.create :posable_one }
        its(:count) { should > 0 }
      end
    end
  end
end
