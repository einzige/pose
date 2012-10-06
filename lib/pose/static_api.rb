# Static helper methods of the Pose gem. 
module Pose

  # By default, doesn't run in tests.
  # Set this to true to test the search functionality.
  CONFIGURATION = { search_in_tests: false }

  class <<self

    ######################
    # PUBLIC METHODS
    #

    # Returns whether Pose is configured to perform search.
    # This setting exists to disable search in tests.
    #
    # @return [false, true]
    def perform_search?
      !(Rails.env == 'test' and !CONFIGURATION[:search_in_tests])
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
