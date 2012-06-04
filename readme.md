# Pose <a href="http://travis-ci.org/#!/kevgo/pose" target="_blank"><img src="https://secure.travis-ci.org/kevgo/pose.png" alt="Build status"></a>

Pose  ("Polymorphic Search") allows fulltext search for ActiveRecord objects.

* Searches over several ActiveRecord classes at once.
* The searchable fulltext content per document can be freely customized.
* Uses the Rails database, no sparate search engines are necessary.
* The algorithm is designed to work with any data store that allows for range queries: SQL and NoSQL.
* The search runs very fast, doing simple queries over fully indexed columns.
* The search index provides data for autocomplete search fields.


# Installation

1.  Add the gem to your Gemfile.

    ```ruby
    gem 'pose'
    ```

2.  Update your gem bundle.

    ```bash
    $ bundle install
    ```

3.  Create the database tables for pose.

    ```bash
    $ rails generate pose
    $ rake db:migrate
    ```

    Pose creates two tables in your database:

    * _pose_words_: index of all the words that occur in the searchable content.
    * _pose_assignments_: lists which word occurs in which document.


# Make your ActiveRecord models searchable

```ruby
class MyClass < ActiveRecord::Base

  # This line tells Pose that your class should be searchable.
  # Once Pose knows that, it will update the search index every time an instance is saved or deleted.
  #
  # The given block must return the searchble content as a string.
  # Note that you can return whatever content you want here,
  # not only data from this object but also data from related objects, class names, etc.
  posify do

    # Only active instances should show up in search results.
    return unless status == :active

    # Return the fulltext content.
    [ self.foo,
      self.parent.bar,
      self.children.map &:name ].join ' '
  end
end
```


# Maintain the search index

The search index is automatically updated when Objects are saved or deleted.

## Indexing existing objects in the database
If you had existing data in your database before adding Pose, it isn't automatically included in the search index.
They will be added on the next save/update operation on them.
You can also manually add existing objects to the search index.

```bash
$ rake pose:reindex_all[MyClass]
```

## Optimizing the search index
The search index keeps all the words that were ever used around, in order to try to reuse them in the future.
If you deleted a lot of objects, you can shrink the memory consumption of the search index by removing unused words.

```bash
$ rake pose:cleanup_index
```

## Removing the search index
For development purposes, or if something went wrong, you can remove the search index for a class
(let's call it "MyClass") completely.

```bash
rake pose:delete_index[MyClass]
```


# Perform a search

```ruby
result = Pose.search 'foo', [MyClass, MyOtherClass]
```

This searches for all instances of MyClass and MyOtherClass that contain the word 'foo'.
The method returns a hash that looks like this:

```ruby
{
  MyClass => [ <myclass instance 1>, <myclass instance 2> ],
  MyOtherClass => [ ],
}
```

In this example, it found two results of type _MyClass_ and no results of type _MyOtherClass_.

Happy searching!  :)


## Search options

```ruby
result = Pose.search 'foo',
                     MyClass,
                     limit: 3,            # Limit the result count to 3.
                     result_type: :ids    # Don't load the resulting objects, return just their ids.
```


# Autocomplete support

Because the search index contains a list of all the words known to the search engine,
it can provide data for autocompletion functionality through the following convenience method:

```ruby
# Returns an array of strings that start with 'cat'.
autocomplete_words = Pose.autocomplete_words 'cat'
```

# Use Pose in your tests

By default, Pose doesn't run in Rails' test environment. This is to not slow down tests due to constant updating of the search index when objects are created.
If you want to test your models search functionality, you need to enable searching in tests:

```ruby
Pose::CONFIGURATION[:search_in_tests] = true
```
    
Please don't forget to set this value to `false` when you are done, or your remaining tests will be slow. A good place to enable/disable this flag is in before/after blocks of your test cases.


# Development

If you find a bug, have a question, or a better idea, please open an issue on the
<a href="https://github.com/kevgo/pose/issues">Pose issue tracker</a>.
Or, clone the repository, make your changes, and submit a pull request.

## Run the unit tests for the Pose Gem

```bash
$ rake spec
```


## Road Map

Pose's algorithm works with all sorts of storage technologies that support range queries, i.e. relational databases,
Google's DataStore, and other NoSQL stores. Right now, only relational databases are supported. NoSQL support is easy,
but not yet implemented.
