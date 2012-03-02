#require "rails/test_help"
#require 'rspec/rails'
require 'rubygems'
require 'bundler/setup'
require 'hashie'
require 'active_record'
require 'active_support/core_ext/module/aliasing'
require 'pose'
require 'active_support/core_ext/string'
require 'faker'
require 'factory_girl'
FactoryGirl.find_definitions

# Configure Rails Environment
ENV["RAILS_ENV"] = "test"
Rails = Hashie::Mash.new({:env => 'test'})
ActiveRecord::Base.send :extend, Pose::BaseAdditions


#require 'your_gem_name' # and any other gems you need


# Load support files
Dir["#{File.dirname(__FILE__)}/support/**/*.rb"].each { |f| require f }
#Dir[Rails.root.join("spec/support/**/*.rb")].each {|f| require f}


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
#  config.use_transactional_fixtures = true

  config.before :suite do
    setup_db
    Pose::CONFIGURATION[:search_in_tests] = true
  end
  
  config.after :suite do 
    teardown_db
  end
end

# Verifies that a taggable object has the given tags.
RSpec::Matchers.define :have_pose_words do |expected|
  match do |actual|
    actual.should have(expected.size).pose_words
    texts = actual.pose_words.map &:text
    expected.each do |expected_word|
      # Note (KG): Can't use text.should include(expected_word) here 
      #            because Ruby thinks I want to include a Module for some reason.
      texts.include?(expected_word).should be_true
    end
  end
  failure_message_for_should do |actual|
    texts = actual.pose_words.map &:text
    "expected that subject would have pose words [#{expected.join ', '}], but it has [#{texts.join ', '}]"
  end
end


class PosableOne < ActiveRecord::Base
  posify { text }
end

class PosableTwo < ActiveRecord::Base
  posify { text }
end

def setup_db
  ActiveRecord::Schema.define(:version => 1) do

    create_table 'posable_ones' do |t|
      t.string 'text'
    end

    create_table 'posable_twos' do |t|
      t.string 'text'
    end

    create_table "pose_assignments" do |t|
      t.integer "pose_word_id",               :null => false
      t.integer "posable_id",                 :null => false
      t.string  "posable_type", :limit => 20, :null => false
    end

    create_table "pose_words" do |t|
      t.string "text", :limit => 80, :null => false
    end
  end
end

def teardown_db
  ActiveRecord::Base.connection.tables.each do |table|
    ActiveRecord::Base.connection.drop_table(table)
  end
end
