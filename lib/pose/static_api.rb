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

      classes = Pose::Helpers.make_array classes
      class_names = classes.map &:name

      # Get the ids of the results.
      result_classes_and_ids = {}
      query_words = query.split(' ').map{|query_word| Pose::Helpers.root_word query_word}.flatten
      query_words.each do |query_word|
        current_word_classes_and_ids = {}
        classes.each { |clazz| current_word_classes_and_ids[clazz.name] = [] }
        query = PoseAssignment.joins(:pose_word) \
                              .select('pose_assignments.posable_id, pose_assignments.posable_type') \
                              .where('pose_words.text LIKE ?', "#{query_word}%") \
                              .where('posable_type IN (?)', class_names)
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
