require "rails/railtie"

module Pose
  class Railtie < Rails::Railtie

    # Load the Pose rake tasks.
    rake_tasks do
      load "tasks/pose_tasks.rake"
    end
  end
end
