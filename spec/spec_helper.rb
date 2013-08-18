if ENV['COVERALLS_CONFIG'] != 'nocoveralls'
  require 'coveralls'
  Coveralls.wear!
end

require 'factory_girl'
require 'faker'
require 'pose'

Dir["#{File.dirname __FILE__}/factories/**/*.rb"].each {|f| require f}
Dir["#{File.dirname __FILE__}/support/**/*.rb"].each {|f| require f}

RSpec.configure do |config|
  SpecManager.manage(config, ENV['POSE_ENV'])
end