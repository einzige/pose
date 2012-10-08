# Pose <a href="http://travis-ci.org/#!/kevgo/pose" target="_blank"><img src="https://secure.travis-ci.org/kevgo/pose.png" alt="Build status"></a> <a href="https://codeclimate.com/github/kevgo/pose" target="_blank"><img src="https://codeclimate.com/badge.png" /></a>

Pose  ("Polymorphic Search") allows fulltext search for ActiveRecord objects in Ruby on Rails.

* Searches over several classes at once.
* The searchable content of each class and document can be freely customized.
* Uses the main Rails database, no separate servers, databases, or search engines are necessary.
* Does not pollute the searchable classes or their database tables with any attributes.
* Allows to combine the fulltext search with any other custom database searches.
* The algorithm is designed to work with any data store that allows for range queries, which covers pretty much every SQL or NoSQL database.
* The search is very fast, doing only simple queries over fully indexed columns.


## Installation

### Set up the gem.

Add the gem to your Gemfile and run `bundle install`

```ruby
gem 'pose'
```

### Create the database tables for pose.

```bash
$ rails generate pose
$ rake db:migrate
```

Pose creates two tables in your database. These tables are automatically populated and kept up to date.

* _pose_words_: index of all the words that occur in the searchable content.
* _pose_assignments_: lists which word occurs in which document.


### Make your ActiveRecord models searchable

```ruby
class MyClass < ActiveRecord::Base

  # This line makes your class searchable.
  # The given block must return the searchble content as a string.
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

Note that you can return whatever content you want in the `posify` block,
not only data from this object, but also data from related objects, class names, etc. 

Now that this class is posified, any `create`, `update`, or `delete` operation on any instance of this class will update the search index automatically.


### Index existing records in your database

Data that existed in your database before adding Pose isn't automatically included in the search index.
You have to index those records manually once. Future updates will happen automatically.

To index all entries of `MyClass`, run `rake pose:reindex_all[MyClass]` on the command line.

At this point, you are all set up. Let's perform a search!


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


### Configure the searched classes

Pose accepts an array of classes to search over. When searching a single class, it can be provided directly, i.e. not as an array.

```ruby
result = Pose.search 'foo', MyClass
```


### Configure the result data

By default, search results are the instances of the objects matching the search query. 
If you want to just get the ids of the search results, and not the full instances, use the parameter `:result_type`.

```ruby
result = Pose.search 'foo', MyClass, result_type: :ids   # Returns ids instead of object instances.
```


### Limit the amount of search results

By default, Pose returns all matching items. Large result sets can become very slow and resource intensive to process.
To limit the result set, use the `:limit` search parameter.

```ruby
result = Pose.search 'foo', MyClass, limit: 20    # Returns only 20 search results.
```


### Combine fulltext search with structured data search

You can add your own ActiveRecord query clauses to a fulltext search operation. 
For example, given a class `Note` that belongs to a `User` class and has a boolean attribute `public`,
finding all public notes from other users containing "foo" is as easy as:

```ruby
result = Pose.search 'foo', MyClass, where: [ public: true, ['user_id <> ?', @current_user.id] ]    
```


## Maintenance

Besides an accasional search index cleanup, Pose is relatively maintenance free. 
The search index is automatically updated when objects are created, updated, or deleted.


### Optimizing the search index

For performance reasons, the search index keeps all the words that were ever used around, in order to try to reuse them as much as possible.
After deleting or changing a large number of objects, you can shrink the memory consumption of Pose's search index by 
removing no longer used search terms from it.

```bash
$ rake pose:index:vacuum
```


### Recreating the search index from scratch
To index existing data in your database, or after loading additional data outside of ActiveRecord into your database,
you should recreate the search index from scratch.

```bash
rake pose:index:recreate[MyClass]
```


### Removing the search index
For development purposes, or if something went wrong, you can remove the search index for a class completely.

```bash
rake pose:index:remove[MyClass]
```


## Use Pose in your tests

By default, Pose doesn't run in Rails' `test` environment. This is to not slow down tests due to constant updating of the search index when objects are created.
If you want to test your models search functionality, you need to enable searching in tests:

```ruby
Pose::CONFIGURATION[:search_in_tests] = true
```
    
Please don't forget to set this value to `false` when you are done, or your remaining tests will be slow. A good place to enable/disable this flag is in before/after blocks of your test cases.


## Development

If you find a bug, have a question, or a better idea, please open an issue on the
<a href="https://github.com/kevgo/pose/issues">Pose issue tracker</a>.
Or, clone the repository, make your changes, and submit a pull request.

### Run the unit tests for the Pose Gem

Pose uses Postgresql for tests, since it is the most strict database.
To run tests, first, create a test database.

```bash
createdb pose_test
```

Then run the tests.

```bash
$ rake spec
```


### Road Map

* add `join` to search parameters
* pagination of search results
* ordering
* weighting search results
* test Pose with more types of data stores (NoSQL, Google DataStore etc)
