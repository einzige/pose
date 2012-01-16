require "rails/railtie"

module Pose

  class Railtie < Rails::Railtie
    rake_tasks do
      load "tasks/pose_tasks.rake"
    end
  end

end
