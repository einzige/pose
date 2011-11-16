# Pose

Pose  ("Polymorphic Search") allows fulltext search for ActiveRecord objects.

* Searches over several ActiveRecord classes at once.
* The searchable fulltext content per document can be freely customized.
* Uses the Rails database, no sparate search engines are necessary.
* The algorithm is designed to work with any data store that allows for range queries: SQL and NoSQL. 
* The search runs very fast, doing simple queries over fully indexed columns.
* The search index provides data for autocomplete search fields.


# Installation

1.  Add the gem to your Gemfile.

        gem 'pose'

2.  Update your gem bundle.

        $ bundle install

3.  Create the database tables for pose.

        $ rails generate pose
        $ rake db:migrate
    
    Pose creates two tables in your database:

    * pose_words: index of all the words that occur in the searchable content.
    * pose_assignments: lists which word occurs in which document.


# Make your ActiveRecord models searchable.

    class MyClass < ActiveRecord::Base
      
      # This line tells Pose that your class should be searchable. 
      # Once Pose knows that, it will update the search index every time an instance is saved or deleted.
      posify
  
      # This method returns the fulltext content that should be indexed.
      # This method returns the text that should be indexed for each instance of the class.
      # Note that you can return whatever content you want here, not only data from this object but also
      # data from related objects, class names, etc.
      def pose_content
      
        # Only active instances should show up in search results.
        return nil unless status == :active
        
        # Return the fulltext content as an array of strings.
        [self.foo, self.parent.bar, self.children.map &:name]
      end
    end


# Maintain the search index.

The search index is automatically updated when Objects are saved or deleted.
To add existing records in the database without having to save them again, 
or recreate the search index, please run 
    rake pose:reindex_all[MyClass]


# Perform a search

    result = Pose.search 'foo', [MyClass, MyOtherClass]

This searches for all instances of MyClass and MyOtherClass for 'foo', 
and returns a hash that looks like this:
    { 
      MyClass => [ <myclass instance 1>, <myclass instance 2> ],
      MyOtherClass => [ ],
    }
    
In this example, it found two results of type MyClass and no results of type MyOtherClass.


# Development

If you find a bug, have a question, or a better idea, please open an issue on the 
<a href="https://github.com/kevgo/pose/issues">Pose issue tracker</a>. 
Or, clone the repository, make your changes, and submit a pull request.

## Unit Tests

    rspec spec/pose_spec.rb
