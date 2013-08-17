if ENV['COVERALLS_CONFIG'] != 'nocoveralls'
  require 'coveralls'
  Coveralls.wear!
end

# This file is copied to spec/ when you run 'rails generate rspec:install'
require 'factory_girl'
require 'faker'
require 'pose'

Dir["#{File.dirname __FILE__}/factories/**/*.rb"].each {|f| require f}
Dir["#{File.dirname __FILE__}/support/**/*.rb"].each {|f| require f}

RSpec.configure do |config|
  #SpecManager.manage(config, :postgres)
  SpecManager.manage(config, :sqlite)
end