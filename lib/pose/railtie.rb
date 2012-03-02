require "rails/railtie"

module Pose

  class Railtie < Rails::Railtie

    # Add the Pose additions to ActiveRecord::Base once it is loaded.
    initializer 'Pose.base_additions' do
      ActiveSupport.on_load :active_record do
        extend Pose::BaseAdditions
      end
    end

    # Load the Pose rake tasks.
    rake_tasks do
      load "tasks/pose_tasks.rake"
    end
  end

end
