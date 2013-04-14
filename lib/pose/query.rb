module Pose
  class Query
    attr_reader :classes, :query_string, :options

    # @param [Array<Class>] classes
    # @param [String] query_string
    def initialize(classes, query_string, options = {})
      @classes = [classes].flatten
      @query_string = query_string
      @options = options
    end

    # @return [Array<String>]
    def class_names
      classes.map &:name
    end

    # @param [Class] klass
    # @return [ActiveRecord::Relation]
    def relation_for(klass)
      unless classes.include?(klass)
        raise ArgumentError, "The class #{klass.name} is not included in this query"
      end

      ids = result_classes_and_ids[klass.name]

      result = klass.where(id: ids)
      result = result.limit(options[:limit])

      if options[:where].present?
        options[:where].each do |scope|
          result = result.where(scope)
        end
      end

      result
    end

    def ids_for(klass)
      ids = result_classes_and_ids[klass.name]

      if options[:where]
        query = klass.scoped
        query = query.limit(options[:limit])

        options[:where].each do |scope|
          query = query.select('id').where('id IN (?)', ids).where(scope)
        end

        klass_ids = klass.connection.select_values(query.to_sql)
        klass_ids.map(&:to_i)
      else
        if options[:limit]
          ids.first(options[:limit])
        else
          ids
        end
      end
    end

    # Gets the ids of the results.
    # @return [Hash<String, Array<Integer>>]
    def result_classes_and_ids
      {}.tap do |classes_and_ids|
        Helpers.query_terms(query_string).each do |query_word|
          Helpers.search_classes_and_ids_for_word(query_word, class_names).each do |class_name, ids|
            Helpers.merge_search_result_word_matches classes_and_ids, class_name, ids
          end
        end
      end
    end

    def results
      @results ||= search
    end

    def result_ids
      {}.tap do |result|
        result_classes_and_ids.each do |class_name, ids|
          result_class = class_name.constantize
          result[result_class] = ids_for(result_class)
        end
      end
    end

    # @return [ActiveRecord::Relation]
    def search
      @results = {}.tap do |result|
        result_classes_and_ids.each do |class_name, ids|
          result_class = class_name.constantize
          result[result_class] = ids.empty? ? [] : relation_for(result_class)
        end
      end
    end
  end
end