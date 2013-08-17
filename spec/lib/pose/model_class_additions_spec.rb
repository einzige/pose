require 'spec_helper'


describe Pose::ModelClassAdditions do
  it 'extends AR models' do
    PosableOne.new.should be_a_kind_of(described_class)
  end

  let(:posable) { FactoryGirl.create(:posable_one, text: '1 2') }
  subject { posable }

  describe "#pose_current_words" do
    its(:pose_current_words) { should == %w{1 2} }
  end

  describe "#pose_fetch_content" do
    its(:pose_fetch_content) { should == '1 2' }
  end

  describe "#pose_fresh_words" do
    its(:pose_fresh_words) { should == %w{1 2} }

    context "having stale words" do
      subject { PosableOne.where(id: posable.id).first }

      before do
        PosableOne.where(id: posable.id).update_all(text: '1 2 3')
      end

      its(:pose_fresh_words) { should == %w{1 2 3} }
    end
  end

  describe "#pose_stale_words" do
    its(:pose_stale_words) { should be_empty }
  end
end