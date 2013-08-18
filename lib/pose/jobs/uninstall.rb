require 'pose/jobs/install'

module Pose
  module Jobs

    # Removes the Pose database tables.
    class KillMigration < ActiveRecord::Migration
      def change
        revert InitialMigration
      end
    end

    class Uninstall
      def perform
        KillMigration.new.change
      end
    end
  end
end
