class SetupPoseSpecs < ActiveRecord::Migration
  def change
    Pose::Jobs::Install.new.perform
  end
end
