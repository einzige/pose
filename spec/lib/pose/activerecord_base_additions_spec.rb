require 'spec_helper'

describe Pose::ActiveRecordBaseAdditions do
  describe "::posify" do
    let(:posable) { create :posable_three, text_1: 't1', text_2: 't2' }

    it 'includes all listed fields in index' do
      posable.pose_fetch_content.should == 't1 t2 |custom text| |from pose block|'
    end
  end
end
