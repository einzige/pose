module Pose

  # TODO: refactor
  class Query
    attr_reader :classes, :query_string, :options

    # @param [Array<Class>] classes
    # @param [String] query_string
    def initialize classes, query_string, options = {}

      # The classes to search on.
      @classes = [classes].flatten

      # The search query.
      @query_string = query_string

      # Additional search options.
      @options = options
    end

    # @return [Array<String>]
    def class_names
      classes.map &:name
    end

    # @param [Class] klass
    # @return [Array<Integer>]
    def ids_for klass
      ids = result_classes_and_ids[klass.name]

      if options[:where]
        query = relation_for(klass)
        klass.connection.select_values(query.to_sql).map(&:to_i)
      else
        options[:limit] ? ids.first(options[:limit]) : ids
      end
    end

    # @param [Class] klass
    # @return [ActiveRecord::Relation]
    def relation_for klass
      ids = result_classes_and_ids[klass.name]
      apply_where_on_scope(klass.where(id: ids)).limit(options[:limit])
    end

    # Gets the ids of the results.
    # TODO: remove Helpers
    # @return [Hash<String, Array<Integer>>]
    def result_classes_and_ids
      @result_classes_and_ids ||= {}.tap do |classes_and_ids|
        Helpers.query_terms(query_string).each do |query_word|
          Helpers.search_classes_and_ids_for_word(query_word, class_names).each do |class_name, ids|
            Helpers.merge_search_result_word_matches classes_and_ids, class_name, ids
          end
        end
      end
    end

    # @return [Hash<Class, Array<Integer>>]
    def result_ids
      {}.tap do |result|
        result_classes_and_ids.each do |class_name, ids|
          result_class = class_name.constantize
          result[result_class] = ids_for(result_class)
        end
      end
    end

    # Cached #search
    # @see #search
    # @return [Hash<Class, ActiveRecord::Relation>]
    def results
      @results ||= search
    end

    # @return [Hash<Class, ActiveRecord::Relation>]
    def search
      {}.tap do |result|
        result_classes_and_ids.each do |class_name, ids|
          result_class = class_name.constantize
          result[result_class] = ids.empty? ? [] : relation_for(result_class)
        end
      end
    end

    private

    # @param [ActiveRecord::Relation]
    # @return [ActiveRecord::Relation]
    # TODO: remove?
    def apply_where_on_scope scope
      result = scope.clone
      if options[:where].present?
        options[:where].each { |scope| result = result.where(scope) }
      end
      result
    end
  end
end
