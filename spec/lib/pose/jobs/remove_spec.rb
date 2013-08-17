require 'spec_helper'


describe Pose::Jobs::Remove do
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
    it { expect{ subject.perform }.not_to raise_error }
  end
end