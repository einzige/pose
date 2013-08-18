# Internal helper methods for the Pose module.
# TODO: remove
module Pose
  module Helpers
    class <<self

      def is_sql_database?
        ['ActiveRecord::ConnectionAdapters::PostgreSQLAdapter',
         'ActiveRecord::ConnectionAdapters::SQLite3Adapter'].include? ActiveRecord::Base.connection.class.name
      end


      # Returns whether the given string is a URL.
      #
      # @param [String] word The string to check.
      #
      # @return [Boolean]
      def is_url? word
        /https?:\/\/(\w)+\.(\w+)/ =~ word
      end


      # Makes the given input an array.
      def make_array input
        [input].flatten
      end


      # Simplifies the given word to a generic search form.
      #
      # @param [String] raw_word The word to make searchable.
      #
      # @return [String] The stemmed version of the word.
      def root_word raw_word
        result = []
        raw_word_copy = raw_word[0..-1]
        raw_word_copy.gsub! '%20', ' '
        raw_word_copy.gsub! /[()*<>'",;\?\-\=&%#]/, ' '
        raw_word_copy.gsub! /\s+/, ' '
        raw_word_copy.split(' ').each do |word|
          if Helpers.is_url?(word)
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

    end
  end
end
