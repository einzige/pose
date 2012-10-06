#require "rails/test_help"
#require 'rspec/rails'
require 'rubygems'
require 'bundler/setup'
require 'hashie'
require 'active_record'
require 'active_support/core_ext/module/aliasing'
require 'active_support/core_ext/string'
require 'pose'
require 'faker'
require 'factory_girl'
require 'database_cleaner'

FactoryGirl.find_definitions

# Configure Rails Environment
ENV["RAILS_ENV"] = "test"
Rails = Hashie::Mash.new({env: 'test'})

# We have no Railtie in these tests --> load Pose manually.
ActiveRecord::Base.send :extend, Pose::BaseAdditions

# Load support files
Dir["#{File.dirname(__FILE__)}/support/**/*.rb"].each { |f| require f }


RSpec.configure do |config|
  # == Mock Framework
  #
  # If you prefer to use mocha, flexmock or RR, uncomment the appropriate line:
  #
  # config.mock_with :mocha
  # config.mock_with :flexmock
  # config.mock_with :rr
  config.mock_with :rspec

  # If you're not using ActiveRecord, or you'd prefer not to run each of your
  # examples within a transaction, remove the following line or assign false
  # instead of true.
  # config.use_transactional_fixtures = true

  config.before :suite do
    setup_db
    Pose::CONFIGURATION[:search_in_tests] = true
    DatabaseCleaner.strategy = :deletion
  end

  config.before :each do
    DatabaseCleaner.start
  end

  config.after :each do
    DatabaseCleaner.clean
  end
end


#####################
# DATABASE SETUP
#

def setup_db
  ActiveRecord::Base.establish_connection adapter:      'postgresql',
                                          database:     'pose_test',
                                          min_messages: 'INFO'

  ActiveRecord::Schema.define(version: 1) do
    unless table_exists? 'posable_ones'
      create_table 'posable_ones' do |t|
        t.string 'text'
        t.boolean 'private'
      end
    end

    unless table_exists? 'posable_twos'
      create_table 'posable_twos' do |t|
        t.string 'text'
        t.boolean 'private'
      end
    end

    unless table_exists? 'pose_assignments'
      create_table "pose_assignments" do |t|
        t.integer "pose_word_id",            null: false
        t.integer "posable_id",              null: false
        t.string  "posable_type", limit: 20, null: false
      end
    end

    unless table_exists? 'pose_words'
      create_table "pose_words" do |t|
        t.string "text", limit: 80, null: false
      end
    end
  end
end
