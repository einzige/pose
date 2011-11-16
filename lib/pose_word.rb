# A single word in the search index.
class PoseWord < ActiveRecord::Base
  has_many :pose_assignments
end