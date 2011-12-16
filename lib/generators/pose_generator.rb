require 'rails/generators'
require 'rails/generators/migration'

class PoseGenerator < Rails::Generators::Base
  include Rails::Generators::Migration
  source_root File.expand_path('../templates', __FILE__)
  
  def create_migration_file
    migration_template 'migration.rb', 'db/migrate/pose.rb'
  end
  
  def self.next_migration_number(path)
      Time.now.utc.strftime("%Y%m%d%H%M%S")
  end
end
