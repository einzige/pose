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
    # @param [String] query
    # @param (Class|[Array<Class>]) classes
    # @param [Hash?] options Additional options.
    #
    # @return [Hash<Class, ActiveRecord::Relation>]
    def search query, classes, options = {}
      {}.tap do |result|
        query = Pose::Query.new(classes, query, options)

        query.result_classes_and_ids.each do |class_name, ids|
          result_class = class_name.constantize

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
              result[result_class] = query.results_for(result_class)
            end
          end
        end
      end
    end
  end
end
