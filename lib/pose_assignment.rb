class PoseAssignment < ActiveRecord::Base
  belongs_to :pose_word
  belongs_to :posable, :polymorphic => true
end