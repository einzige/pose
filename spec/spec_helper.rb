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
  #config.order = "random"

  config.include FactoryGirl::Syntax::Methods

  config.before(:each) do
    DatabaseCleaner.start
  end

  config.after(:each) do
    DatabaseCleaner.clean
  end

  spec_manager = SpecManager.new(:default)

  config.before(:suite) do
    spec_manager.init!
    DatabaseCleaner.strategy = :transaction
    DatabaseCleaner.clean_with(:truncation)
  end

  config.after(:suite) do
    spec_manager.drop_database
  end
end