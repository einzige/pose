require 'rails/generators'
require 'rails/generators/migration'

module Pose
  module Generators

    class InstallGenerator < Rails::Generators::Base
      include Rails::Generators::Migration
      source_root File.expand_path(File.join(File.dirname(__FILE__), 'templates')) 

      def create_migration_file
        say ''
        say '  Creating database migration for the Pose tables.'
        say ''
        migration_template 'install_migration.rb', 'db/migrate/install_pose.rb'
        say ''
      end

      def installation_instructions
        say ''
        say '  All done! You need to do two things now:'
        say ''
        say '    1. Run the database migration'
        say ''
        say '       rake db:migrate', Thor::Shell::Color::BOLD
        say ''
        say ''
        say '    2. Add a posify block to all your models.'
        say '       Here is an example:'
        say ''
        say '         class MyClass < ActiveRecord::Base'
        say '           ...'
        say ''
        say '           posify do', Thor::Shell::Color::BOLD
        say '             # return searchable text as a string here', Thor::Shell::Color::BOLD
        say '           end', Thor::Shell::Color::BOLD
        say ''
        say '           ...'
        say '         end'
        say ''
        say ''
        say '  Happy searching! :)'
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
