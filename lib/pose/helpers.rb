# Internal helper methods for the Pose module.
# TODO: remove
module Pose
  module Helpers
    class <<self

      # Returns all strings that are in new_words, but not in existing_words.
      # Helper method.
      #
      # @param [Array<String>] existing_words The words that are already associated with the object.
      # @param [Array<String>] new_words The words thet the object should have from now on.
      #
      # @return [Array<String>] The words that need to be added to the existing_words array.
      def get_words_to_add existing_words, new_words
        new_words - existing_words.map(&:text)
      end


      # Helper method.
      # Returns the id of all word objects that are in existing_words, but not in new_words.
      #
      # @param [Array<String>] existing_words The words that are already associated with the object.
      # @param [Array<String>] new_words The words thet the object should have from now on.
      #
      # @return [Array<String>] The words that need to be removed from the existing_words array.
      def get_words_to_remove existing_words, new_words
        existing_words.map do |existing_word|
          existing_word unless new_words.include?(existing_word.text)
        end.compact
      end


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
        URI::parse(word).scheme == 'http'
      rescue URI::InvalidURIError
        false
      end


      # Merges the given posable object ids for a single query word into the given search result.
      def merge_search_result_word_matches result, class_name, ids
        if result.has_key? class_name
          result[class_name] = result[class_name] & ids
        else
          result[class_name] = ids
        end
      end


      # Returns a hash mapping classes to ids for the a single given word.
      def search_classes_and_ids_for_word word, class_names
        result = {}.tap { |hash| class_names.each { |class_name| hash[class_name] = [] }}
        query = Pose::Assignment.joins(:word) \
                          .select('pose_assignments.posable_id, pose_assignments.posable_type') \
                          .where('pose_words.text LIKE ?', "#{word}%") \
                          .where('posable_type IN (?)', class_names)
        Pose::Assignment.connection.select_all(query.to_sql).each do |pose_assignment|
          result[pose_assignment['posable_type']] << pose_assignment['posable_id'].to_i
        end
        result
      end


      # Makes the given input an array.
      def make_array input
        [input].flatten
      end


      # Returns the search terms that are contained in the given query.
      def query_terms query
        query.split(' ').map{|query_word| Helpers.root_word query_word}.flatten.uniq
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
