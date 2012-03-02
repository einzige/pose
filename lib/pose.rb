# Note (KG): Need to include the rake DSL here to prevent deprecation warnings in the Rakefile.
require 'rake'
include Rake::DSL if defined? Rake::DSL

require 'pose/static_helpers'
require 'pose/base_additions'
require 'pose/model_additions'
require 'pose/railtie' if defined? Rails
require 'pose_assignment'
require 'pose_word'
