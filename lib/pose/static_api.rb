# This is the public API of static helper methods of the Pose gem.

module Pose

  # By default, performs search functionality everywhere.
  # Since this can severely slow down your tests,
  # disable this setting in your "test" environments,
  # and enable it for tests that verify search functionality.
  CONFIGURATION = { perform_search: true }

  class <<self

    # Returns all words that begin with the given query string.
    # This can be used for autocompletion functionality.
    #
    # @param [String]
    # @return [Array<String>]
    def autocomplete_words query
      return [] if query.blank?
      Word.where('text LIKE ?', "#{Helpers.root_word(query)[0]}%").map(&:text)
    end


    # Returns whether Pose is configured to perform search.
    # This setting exists to disable search in tests.
    #
    # @return [false, true]
    def perform_search?
      CONFIGURATION.has_key?(:perform_search) ? CONFIGURATION[:perform_search] : true
    end


    # Returns all objects matching the given query.
    #
    # @param [String] query_string
    # @param (Class|[Array<Class>]) classes
    # @param [Hash?] options Additional options.
    #
    # @return [Hash<Class, ActiveRecord::Relation>]
    def search query_string, classes, options = {}
      Pose::Query.new(classes, query_string, options).search
    end
  end
end
