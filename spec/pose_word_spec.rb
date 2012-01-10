require 'spec_helper'

describe PoseWord do
  
  before :all do
    PoseWord.delete_all
  end
  
  describe 'remove_unused_words' do

    it 'removes unused words' do
      Factory :pose_word
      PoseWord.remove_unused_words
      PoseWord.count.should == 0
    end
    
    it "doesn't remove used words" do
      snippet = Factory :posable_one
      PoseWord.remove_unused_words
      PoseWord.count.should > 0
    end
  end
end
