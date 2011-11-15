= Pose

Pose  ("Polymorphic Search") allows fulltext search for ActiveRecord objects.
* You can search over several ActiveRecord classes at once.
* The searchable content per document can be freely defined.
* It uses the built-in database, no specialized search engines are necessary.
* It works with a variety of data store types, ranging from SQL databases to NoSQL column stores
  like Google's data store.
* The search runs very fast.


= Installation

1. Add the gem to your Gemfile.
    gem 'pose'

2. Update your gem bundle.
    bundle install

3. Create the database tables for pose.
    rails generate pose
    rake db:migrate

4. Make your ActiveRecord models searchable.

