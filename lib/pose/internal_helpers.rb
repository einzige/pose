# Internal helper methods for the Pose module.
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
          if Pose::Helpers.is_url?(word)
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


      # Returns all words that begin with the given query string.
      # This can be used for autocompletion functionality.
      #
      # @param [String]
      # @return [Array<String>]
      def autocomplete_words query
        return [] if query.blank?
        PoseWord.where('text LIKE ?', "#{Pose::Helpers.root_word(query)[0]}%").map(&:text)
      end

    end
  end
end
