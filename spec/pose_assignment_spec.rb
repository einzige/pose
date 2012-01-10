require 'spec_helper'

describe PoseAssignment do

  before :all do
    PoseAssignment.delete_all
  end
  
  describe "cleanup_orphaned_pose_assignments" do
    
    it "deletes the assignment if the posable object doesn't exist" do
      Factory :pose_assignment, :posable_id => 2, :posable_type => 'PosableOne'
      PoseAssignment.count.should > 0
      PoseAssignment.cleanup_orphaned_pose_assignments
      PoseAssignment.should have(0).items
    end
    
    it "deletes the assignment if the pose_word doesn't exist" do
      assignment = Factory :pose_assignment, :pose_word => nil, :pose_word_id => 27
      PoseAssignment.cleanup_orphaned_pose_assignments
      PoseAssignment.find_by_id(assignment.id).should be_nil
    end
    
    it "doesn't delete the assignment if it is still used" do
      assignment = Factory :pose_assignment
      PoseAssignment.cleanup_orphaned_pose_assignments
      PoseAssignment.find_by_id(assignment.id).should_not be_nil
    end
  end
  
end
