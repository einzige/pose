# Static helper methods of the Pose gem. 
module Pose

  # By default, doesn't run in tests.
  # Set this to true to test the search functionality.
  CONFIGURATION = { search_in_tests: false }

  class <<self

    # Returns whether Pose is configured to perform search.
    # This setting exists to disable search in tests.
    #
    # @return [false, true]
    def perform_search?
      !(Rails.env == 'test' and !CONFIGURATION[:search_in_tests])
    end

    # Returns all words that begin with the given query string.
    # This can be used for autocompletion functionality.
    #
    # @param [String]
    # @return [Array<String>]
    def autocomplete_words query
      return [] if query.blank?
      PoseWord.where('text LIKE ?', "#{Pose.root_word(query)[0]}%").map(&:text)
    end

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
        if Pose.is_url?(word)
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

    # Returns all objects matching the given query.
    #
    # @param [String] query
    # @param (Class|[Array<Class>]) classes
    # @param [Hash?] options Additional options.
    #
    # @return [Hash<Class, ActiveRecord::Relation>]
    def search query, classes, options = {}

      # Turn 'classes' into an array.
      classes = [classes].flatten
      classes_names = classes.map &:name
      classes_names = classes_names[0] if classes_names.size == 1

      # Get the ids of the results.
      result_classes_and_ids = {}
      query_words = query.split(' ').map{|query_word| Pose.root_word query_word}.flatten
      query_words.each do |query_word|
        current_word_classes_and_ids = {}
        classes.each { |clazz| current_word_classes_and_ids[clazz.name] = [] }
        query = PoseAssignment.joins(:pose_word) \
                              .select('pose_assignments.posable_id, pose_assignments.posable_type') \
                              .where('pose_words.text LIKE ?', "#{query_word}%") \
                              .where('posable_type IN (?)', classes_names)
        PoseAssignment.connection.select_all(query.to_sql).each do |pose_assignment|
          current_word_classes_and_ids[pose_assignment['posable_type']] << pose_assignment['posable_id'].to_i
        end
        # This is the old ActiveRecord way. Removed for performance reasons.
        # query.each do |pose_assignment|
        #   current_word_classes_and_ids[pose_assignment.posable_type] << pose_assignment.posable_id
        # end

        current_word_classes_and_ids.each do |class_name, ids|
          if result_classes_and_ids.has_key? class_name
            result_classes_and_ids[class_name] = result_classes_and_ids[class_name] & ids
          else
            result_classes_and_ids[class_name] = ids
          end
        end
      end

      # Load the results by id.
      {}.tap do |result|
        result_classes_and_ids.each do |class_name, ids|
          result_class = Kernel.const_get class_name

          if ids.size == 0
            # Handle no results.
            result[result_class] = []

          else
            # Here we have results.

            # Limit.
            ids = ids.slice(0, options[:limit]) if options[:limit]

            if options[:result_type] == :ids
              # Ids requested for result.

              if options.has_key? :scope
                # We have a scope.
                options[:scope].each do |scope|
                  result[result_class] = result_class.select('id').where(scope).map(&:id)
                end
              else
                result[result_class] = ids
              end

            else
              # Classes requested for result.

              result[result_class] = result_class.where(id: ids)
              if options.has_key? :scope
                options[:scope].each do |scope|
                  result[result_class] = result[result_class].where(scope)
                end
              end
            end
          end
        end
      end
    end
  end
end
