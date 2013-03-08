require 'spec_helper'

module Pose
  describe Assignment do

    describe "delete_class_index" do

      before :each do
        FactoryGirl.create :assignment, posable_id: 1, posable_type: 'PosableOne'
        FactoryGirl.create :assignment, posable_id: 2, posable_type: 'PosableTwo'
        Assignment.delete_class_index PosableOne
      end

      it "deletes all Assignments for the given class" do
        expect(Assignment.where(posable_type: 'PosableOne')).to have(0).items
      end

      it "doesn't delete Assignments for other classes" do
        expect(Assignment.where(posable_type: 'PosableTwo')).to have(1).items
      end
    end


    describe "cleanup_orphaned_pose_assignments" do

      it "deletes the assignment if the posable object doesn't exist" do
        FactoryGirl.create :assignment, posable_id: 2, posable_type: 'PosableOne'
        expect(Assignment.count).to be > 0
        Assignment.cleanup_orphaned_pose_assignments
        expect(Assignment.count).to eql 0
      end

      it "deletes the assignment if the word doesn't exist" do
        assignment = FactoryGirl.create :assignment, word: nil, word_id: 27
        Assignment.cleanup_orphaned_pose_assignments
        expect(Assignment.find_by_id(assignment.id)).to be_nil
      end

      it "doesn't delete the assignment if it is still used" do
        assignment = FactoryGirl.create :assignment
        Assignment.cleanup_orphaned_pose_assignments
        expect(Assignment.find_by_id(assignment.id)).to_not be_nil
      end
    end
  end
end
