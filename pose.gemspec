$:.push File.expand_path('../lib', __FILE__)

# Maintain your gem's version:
require 'pose/version'

# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.name        = 'pose'
  s.version     = Pose::VERSION
  s.authors     = ['Kevin Goslar']
  s.email       = ['kevin.goslar@gmail.com']
  s.homepage    = 'http://github.com/kevgo/pose'
  s.summary     = 'A polymorphic, storage-system independent search engine for Ruby on Rails.'
  s.description = "Pose ('Polymorphic Search') allows fulltext search for ActiveRecord objects."

  s.files = Dir['{app,config,db,lib}/**/*'] + ['MIT-LICENSE', 'Rakefile', 'README.md']
  s.test_files = Dir['spec/**/*']

  s.add_dependency 'rails', '>= 3.0.0'
  s.add_dependency 'ruby-progressbar'

  s.add_development_dependency 'factory_girl_rails'
  s.add_development_dependency 'faker'
  s.add_development_dependency 'guard-rspec'
  s.add_development_dependency 'rspec-rails'
  s.add_development_dependency 'sqlite3'

  s.post_install_message = <<-END

HEADS UP! If you have used Pose 1.x before,
you need to update your database tables!

* run: rails g pose:upgrade
* run: rake db:migrate

For more information, see: https://github.com/kevgo/pose
END

end
