# POlymorphic SEarch <a href="http://travis-ci.org/#!/kevgo/pose" target="_blank"><img src="https://secure.travis-ci.org/kevgo/pose.png" alt="Build status"></a> [![Code Climate](https://codeclimate.com/github/kevgo/pose.png)](https://codeclimate.com/github/kevgo/pose) [![Coverage Status](https://coveralls.io/repos/kevgo/pose/badge.png?branch=master)](https://coveralls.io/r/kevgo/pose) [![Dependency Status](https://gemnasium.com/kevgo/pose.png)](https://gemnasium.com/kevgo/pose)

A database agnostic fulltext search engine for ActiveRecord objects. See also [Pose Rails Adapter](http://github.com/einzige/pose-rails).

* Searches over several classes at once.
* The searchable content of each class and document can be freely customized.
* Uses application database - no separate servers, databases, or search engines required.
* Does not pollute the searchable classes nor their database tables.
* Very fast search, doing only simple queries over fully indexed columns.
* Allows to augment the fulltext search query with your own joins and where clauses.


## Installation

### Versions

* __2.x__ for _Rails 3.x_ compatibilty
* __3.0__ for _Rails 4_ compatibilty
* __3.1__ introduces a new setup. The _pose_ gem is now a generic Ruby gem that works
    with any Ruby web server that uses ActiveRecord, like [Sinatra](http://www.sinatrarb.com),
    [Padrino](http://www.padrinorb.com), or [Rails](http://rubyonrails.org).
    Generators for installation and uninstallation are extracted into the
    [pose_rails](https://github.com/po-se/pose-rails) gem.


### Set up the gem.

Add the gem to your Gemfile and run `bundle install`

```ruby
gem 'pose'
```

### Create the database tables for pose.

```bash
$ rake pose:install
```

Pose creates two tables in your database. These tables are automatically populated and kept up to date.

* _pose_words_: index of all the words that occur in the searchable content.
* _pose_assignments_: lists which word occurs in which document.


### Make your ActiveRecord models searchable

Each model defines the searchable content through the `posify` method.
Valid parameters are
* names of __fields__
* names of __methods__
* a __block__

The value/result of each parameter is added to the search index for this instance.
Here are a few examples:

```ruby
class User < ActiveRecord::Base
  # first_name and last_name are attributes

  # This line makes the class searchable.
  posify :first_name, :last_name, :address

  def address
    "#{street} #{city} #{state}"
  end
end
```

```ruby
class MyClass < ActiveRecord::Base

  # This line makes the class searchable.
  posify do

    # Only active instances should show up in search results.
    return nil unless status == :active

    # The searchable content.
    [ self.foo,
      self.parent.bar,
      self.children.map &:name ].join ' '
  end
end
```

You can mix and match all parameter types for `posify` at will.
Note that you can return whatever content you want in the `posify` block,
not only data from this object, but also data from related objects, class names, etc.

Now that this class is posified, any `create`, `update`, or `delete` operation on any instance of this class will update the search index automatically.


### Index existing records in your database

Data that existed in your database before adding Pose isn't automatically included in the search index.
You have to index those records manually once. Future updates will happen automatically.

To index all entries of `MyClass`, run `rake 'pose:reindex_all[MyClass]'` on the command line.

At this point, you are all set up. Let's perform a search!


### Upgrading from version 1.x

Version 2 is a proper Rails engine, and comes with a slightly different database table schema.
Upgrading is as simple as

```bash
$ rails generate pose:upgrade
$ rake db:migrate
```


## Searching

To search, simply call Pose's `search` method, and tell it the search query as well as in which classes it should search.

```ruby
result = Pose.search 'foo', [MyClass, MyOtherClass]
```

This searches for all instances of `MyClass` and `MyOtherClass` that contain the word 'foo'.
The method returns a hash that looks like this:

```ruby
{
  MyClass => [ <myclass instance 1>, <myclass instance 2> ],
  MyOtherClass => [ ],
}
```

In this example, it found two results of type _MyClass_ and no results of type _MyOtherClass_.
A Pose search returns the object instances that match the query. This behavior, as well as many others, is configurable through
search options.


## Search options

### Configure the searched classes

Pose accepts an array of classes to search over.

```ruby
result = Pose.search 'search text', [MyClass, MyOtherClass]
```

When searching a single class, it can be provided directly, i.e. not as an array.

```ruby
result = Pose.search 'foo', MyClass
```


### Configure the result data

Search results are the instances of the objects matching the search query.
If you want to just get the ids of the search results, and not the full instances, use the parameter `:result_type`.

```ruby
# Returns ids instead of object instances.
result = Pose.search 'foo', MyClass, result_type: :ids
```


### Limit the amount of search results

By default, Pose returns all matching items.
To limit the result set, use the `:limit` search parameter.

```ruby
# Returns only 20 search results.
result = Pose.search 'foo', MyClass, limit: 20
```


### Combine fulltext search with structured data search

You can add your own ActiveRecord query clauses (JOINs and WHEREs) to a fulltext search operation.
For example, given a class `Note` that belongs to a `User` class and has a boolean attribute `public`,
finding all public notes from other users containing "foo" is as easy as:

```ruby
result = Pose.search 'foo',
                     Note,
                     joins: Note,
                     where: [ ['notes.public = ?', true],
                              ['user_id <> ?', @current_user.id] ] ]
```

Combining ActiveRecord query clauses with fulltext search only works when searching over a single class.


## Maintenance

Besides an accasional search index cleanup, Pose is relatively maintenance free.
The search index is automatically updated when objects are created, updated, or deleted.


### Optimizing the search index

The search index keeps all the words that were ever used around.
After deleting or changing a large number of objects, you can shrink the database storage consumption of Pose's search index by
removing no longer used search terms from it.

```bash
$ rake pose:index:vacuum
```


### Recreating the search index from scratch
To index existing data in your database, or after buld-loading data outside of ActiveRecord into your database,
you should recreate the search index from scratch.

```bash
rake pose:index:reindex_all[MyClass]
```


## Uninstalling

To remove all traces of Pose from your database, run:

```bash
rails generate pose:remove
```

Also don't forget to remove the `posify` block from your models as well as the _pose_ gem from your Gemfile.


## Use Pose in your tests

Pose can slow down your tests, because it updates the search index on every `:create`, `:update`, and `:delete`
operation in the database.
To avoid that in your not search-related tests, you can disable Pose in your `test` environments,
and only enable it for the tests that actually need search functionality.

To disable Pose for tests, add this line to `config/environments/test.rb`

```ruby
Pose::CONFIGURATION[:perform_search] = false
```

Now, with search disabled in the test environment, enable Pose in some of your tests
by setting the same value to `true` inside the tests:

```ruby

context 'with search enabled' do

  before :all do
    Pose::CONFIGURATION[:perform_search] = true
  end

  after :all do
    Pose::CONFIGURATION[:perform_search] = false
  end

  it 'has search enabled in this test here...'

  it 'has search enabled in this test as well...'
end
```


## Development

If you find a bug, have a question, or a better idea, please open an issue on the
<a href="https://github.com/kevgo/pose/issues">Pose issue tracker</a>.
Or, clone the repository, make your changes, and submit a unit-tested pull request!

### Run the unit tests for the Pose Gem

Pose can work with Sqlite3, Postgesql and MySQL by default.
To run tests, please create database configuration file `spec/support/config/database.yml`, please refer to the template:
[spec/support/config/database.yml.example](spec/support/config/database.yml.example)

Then run the tests.

```bash
bundle exec rake test
```

### Road Map

* pagination of search results
* ordering
* weighting search results
* test Pose with more types of data stores (NoSQL, Google DataStore etc)
