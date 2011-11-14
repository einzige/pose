$:.push File.expand_path("../lib", __FILE__)

# Maintain your gem's version:
require "pose/version"

# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.name        = "pose"
  s.version     = Pose::VERSION
  s.authors     = ["Kevin Goslar"]
  s.email       = ["kevin.goslar@gmail.com"]
  s.homepage    = "TODO"
  s.summary     = "A polymorphic, storage-system independent search engine for Ruby on Rails."
  s.description = "TODO: Description of Pose."

  s.files = Dir["{app,config,db,lib}/**/*"] + ["MIT-LICENSE", "Rakefile", "README.rdoc"]
  s.test_files = Dir["test/**/*"]

  s.add_dependency "rails", "~> 3.1.1"

  s.add_development_dependency "sqlite3"
  s.add_development_dependency "rspec-rails"
end
