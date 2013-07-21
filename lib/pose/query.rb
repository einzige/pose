module Pose
  # Represents a search query.
  #
  # Provides convenient access to all elements of the search query:
  #   * fulltext
  #   * classes to search in
  #   * additional JOINs
  #   * additional WHEREs
  class Query

    attr_reader :classes, :text, :options


    def initialize classes, text, options = {}
      @classes = [classes].flatten
      @text = text
      @options = options
    end


    # The names of the classes to search in.
    # @return [Array<String>]
    def class_names
      classes.map &:name
    end


    # Returns whether this query contains custom JOIN expressions.
    def has_joins?
      !@options[:joins].blank?
    end


    # Returns whether the query defines a limit on the number of results.
    def has_limit?
      !@options[:limit].blank?
    end


    # Returns whether this query contains WHERE clauses.
    def has_where?
      !@options[:where].blank?
    end


    # Returns whether only result ids are requested,
    # opposed to full objects.
    def ids_requested?
      @options[:result_type] == :ids
    end


    # Returns the custom JOIN expressions of this query.
    def joins
      @joins ||= [@options[:joins]].flatten.compact
    end


    # Returns the limitation on the number of results.
    def limit
      @options[:limit]
    end


    # Returns the search terms that are contained in the given query.
    def query_words
      @query_words ||= Query.query_words @text
    end


    def self.query_words query_string
      query_string.split(' ').map{|query_word| Helpers.root_word query_word}.flatten.uniq
    end


    # Returns the WHERE clause of this query.
    def where
      return [] unless has_where?
      if @options[:where].size == 2 and @options[:where][0].class == String
        return [ @options[:where] ]
      end
      @options[:where]
    end
  end
end
