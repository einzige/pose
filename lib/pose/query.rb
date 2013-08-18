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
      @options[:joins].present?
    end


    # Returns whether the query defines a limit on the number of results.
    def has_limit?
      @options[:limit].present?
    end


    # Returns whether this query contains WHERE clauses.
    def has_where?
      @options[:where].present?
    end


    # Returns whether only result ids are requested,
    # opposed to full objects.
    def ids_requested?
      @options[:result_type] == :ids
    end


    # Returns whether the given string is a URL.
    #
    # @param [String] word The string to check.
    #
    # @return [Boolean]
    def self.is_url? word

      # Handle localhost separately.
      return true if /^http:\/\/localhost(:\d+)?/ =~ word

      /^https?:\/\/([\w\.])+\.([\w\.])+/ =~ word
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
      query_string.split(' ').map{|query_word| Query.root_word query_word}.flatten.uniq
    end


    # Simplifies the given word to a generic search form.
    #
    # @param [String] raw_word The word to make searchable.
    #
    # @return [String] The stemmed version of the word.
    def self.root_word raw_word
      result = []
      raw_word_copy = raw_word[0..-1]
      raw_word_copy.gsub! '%20', ' '
      raw_word_copy.gsub! /[()*<>'",;\?\-\=&%#]/, ' '
      raw_word_copy.gsub! /\s+/, ' '
      raw_word_copy.split(' ').each do |word|
        if Query.is_url?(word)
          result.concat word.split(/[\.\/\:]/).delete_if(&:blank?)
        else
          word.gsub! /[\-\/\._:]/, ' '
          word.gsub! /\s+/, ' '
          word.split(' ').each do |w|
            stemmed_word =  w.parameterize.singularize
            result.concat stemmed_word.split ' '
          end
        end
      end
      result.uniq
    end


    # Returns the WHERE clause of this query.
    def where
      return [] unless has_where?
      return [ @options[:where] ] if @options[:where].size == 2 and @options[:where][0].class == String
      @options[:where]
    end
  end
end
