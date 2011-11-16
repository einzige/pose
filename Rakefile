#!/usr/bin/env rake
begin
  require 'bundler/setup'
rescue LoadError
  puts 'You must `gem install bundler` and `bundle install` to run rake tasks'
end
require 'rspec/core/rake_task'

Bundler::GemHelper.install_tasks

desc 'Default: run the specs and features.'
task :default => 'spec:unit' do
  system("bundle exec rake spec")
end

namespace :spec do

  desc "Run unit specs"
  RSpec::Core::RakeTask.new('unit') do |t|
    t.pattern = 'spec/{*_spec.rb}'
  end
end

desc "Run the unit tests"
task :spec => ['spec:unit']

