require 'spec_helper'


describe Pose::Jobs::ReindexAll do
  let(:klass) { PosableOne }
  subject { described_class.new(klass) }

  describe "#initialize" do
    its(:klass) { should == PosableOne }

    context "string given" do
      let(:klass) { 'PosableOne' }
      its(:klass) { should == PosableOne }
    end
  end

  describe "#perform" do
    let(:posable_one_1) { FactoryGirl.create(:posable_one, text: '1') }
    let(:posable_one_2) { FactoryGirl.create(:posable_one, text: '1 2') }

    context "records were updated without running callbacks" do
      before do
        PosableOne.where(id: posable_one_1.id).update_all(text: '1 2')
        PosableOne.where(id: posable_one_2.id).update_all(text: '1')
      end

      it { expect { subject.perform }.to change{ posable_one_1.pose_words.count }.from(1).to(2) }
      it { expect { subject.perform }.to change{ posable_one_2.pose_words.count }.from(2).to(1) }
    end
  end
end
