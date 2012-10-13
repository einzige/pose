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
      PoseWord.where('text LIKE ?', "#{Pose::Helpers.root_word(query)[0]}%").map(&:text)
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
    # @param [String] query
    # @param (Class|[Array<Class>]) classes
    # @param [Hash?] options Additional options.
    #
    # @return [Hash<Class, ActiveRecord::Relation>]
    def search query, classes, options = {}


      # Get the ids of the results.
      class_names = Pose::Helpers.make_array(classes).map &:name
      result_classes_and_ids = {}
      Pose::Helpers.query_terms(query).each do |query_word|
        Pose::Helpers.search_classes_and_ids_for_word(query_word, class_names).each do |class_name, ids|
          Pose::Helpers.merge_search_result_word_matches result_classes_and_ids, class_name, ids
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

            if options[:result_type] == :ids
              # Ids requested for result.

              if options[:where].blank?
                # No scope.
                result[result_class] = options[:limit] ? ids.slice(0, options[:limit]) : ids
              else
                # We have a scope.
                options[:where].each do |scope|
                  query = result_class.select('id').where('id IN (?)', ids).where(scope)
                  query = query.limit(options[:limit]) unless options[:limit].blank?
                  query = query.to_sql
                  result[result_class] = result_class.connection.select_values(query).map(&:to_i)
                end
              end

            else
              # Classes requested for result.

              result[result_class] = result_class.where(id: ids)
              result[result_class] = result[result_class].limit(options[:limit]) unless options[:limit].blank?
              unless options[:where].blank?
                options[:where].each do |scope|
                  result[result_class] = result[result_class].where('id IN (?)', ids).where(scope)
                end
              end
            end
          end
        end
      end
    end

  end
end
