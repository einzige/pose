require 'rails/generators'
require 'rails/generators/migration'

module Pose
  module Generators

    class UpgradeGenerator < Rails::Generators::Base
      include Rails::Generators::Migration
      source_root File.expand_path(File.join(File.dirname(__FILE__), 'templates'))

      def create_migration_file
        say ''
        say '  Creating database migration to upgrade your Pose tables.'
        say ''
        migration_template 'upgrade_migration.rb', 'db/migrate/pose_upgrade.rb'
        say ''
      end

      def installation_instructions
        say '  All done! You need to do is run db:migrate!'
        say ''
      end


      private

      # Helper method for creating the migration.
      def self.next_migration_number(path)
          Time.now.utc.strftime("%Y%m%d%H%M%S")
      end
    end

  end
end

