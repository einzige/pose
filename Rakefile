#!/usr/bin/env rake

begin
  require 'bundler/setup'
rescue LoadError
  puts 'You must `gem install bundler` and `bundle install` to run rake tasks'
end

Bundler::GemHelper.install_tasks

# RSpec tasks.
require 'rspec/core/rake_task'

RSpec::Core::RakeTask.new :spec_mysql do
  ENV['POSE_ENV'] = 'mysql'
end

RSpec::Core::RakeTask.new :spec_mysql2 do
  ENV['POSE_ENV'] = 'mysql2'
end

RSpec::Core::RakeTask.new :spec_sqlite do
  ENV['POSE_ENV'] = 'sqlite'
end

RSpec::Core::RakeTask.new :spec_postgres do
  ENV['POSE_ENV'] = 'postgres'
end

RSpec::Core::RakeTask.new :spec_mysql_ci do
  ENV['POSE_ENV'] = 'mysql_ci'
end

RSpec::Core::RakeTask.new :spec_mysql2_ci do
  ENV['POSE_ENV'] = 'mysql2_ci'
end

RSpec::Core::RakeTask.new :spec_sqlite_ci do
  ENV['POSE_ENV'] = 'sqlite_ci'
end

RSpec::Core::RakeTask.new :spec_postgres_ci do
  ENV['POSE_ENV'] = 'postgres_ci'
end

task :test_ci => [:spec_sqlite_ci, :spec_postgres_ci, :spec_mysql2_ci]
task :test    => [:spec_sqlite,    :spec_postgres,    :spec_mysql2]
task :default => :test_ci
