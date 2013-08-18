module Pose

  # A search operation.
  #
  # Is given a query and search options, and returns the search results.
  class Search

    # @param [Array<Class>] classes The classes to search over.
    # @param [String] query_string The full-text part of the search query.
    # @param options Additional search options:
    #    * where: additional where clauses
    #    * join: additional join clauses
    def initialize classes, query_string, options = {}
      @query = Query.new classes, query_string, options
    end


    # Adds the given join expression to the given arel query.
    def add_join arel, join_expression
      case join_expression.class.name
        when 'Class'
          table_name = join_expression.name.tableize
          return arel.joins "INNER JOIN #{table_name} ON pose_assignments.posable_id=#{table_name}.id AND pose_assignments.posable_type='#{join_expression.name}'"
        when 'String', 'Symbol'
          return arel.joins join_expression
        else
          raise "Unknown join expression: #{join_expression}"
      end
    end


    # Creates a JOIN to the given expression.
    def add_joins arel
      @query.joins.inject(arel) do |memo, join_data|
        add_join memo, join_data
      end
    end


    # Adds the WHERE clauses from the given query to the given arel construct.
    def add_wheres arel
      @query.where.inject(arel) { |memo, where| memo.where where }
    end


    # Returns an empty result structure.
    def empty_result
      {}.tap do |result|
        @query.class_names.each do |class_name|
          result[class_name] = []
        end
      end
    end


    # Truncates the result set based on the :limit parameter in the query.
    def limit_ids result
      return unless @query.has_limit?
      result.each do |clazz, ids|
        result[clazz] = ids.slice 0, @query.limit
      end
    end


    # Converts the ids to classes, if the user wants classes.
    def load_classes result
      return if @query.ids_requested?
      result.each do |clazz, ids|
        if ids.size > 0
          result[clazz] = clazz.where(id: ids)
        end
      end
    end


    # Merges the given posable object ids for a single query word into the given search result.
    # Helper method for :search_words.
    def merge_search_result_word_matches result, class_name, ids
      if result.has_key? class_name
        result[class_name] = result[class_name] & ids
      else
        result[class_name] = ids
      end
    end


    # Returns the search results cached.
    # Use this method to access the results of the search.
    def results
      @results ||= search
    end


    # Performs a complete search.
    # Clients should use :results to perform a search,
    # since it caches the results.
    def search
      {}.tap do |result|
        search_words.each do |class_name, ids|
          result[class_name.constantize] = ids
        end
        limit_ids result
        load_classes result
      end
    end


    # Finds all matching ids for a single word of the search query.
    def search_word word
      empty_result.tap do |result|
        data = Assignment.joins(:word) \
                         .select('pose_assignments.posable_id, pose_assignments.posable_type') \
                         .where('pose_words.text LIKE ?', "#{word}%") \
                         .where('pose_assignments.posable_type IN (?)', @query.class_names)
        data = add_joins data
        data = add_wheres data
        Assignment.connection.select_all(data.to_sql).each do |pose_assignment|
          result[pose_assignment['posable_type']] << pose_assignment['posable_id'].to_i
        end
      end
    end


    # Returns all matching ids for all words of the search query.
    def search_words
      {}.tap do |result|
        @query.query_words.each do |query_word|
          search_word(query_word).each do |class_name, ids|
            merge_search_result_word_matches result, class_name, ids
          end
        end
      end
    end
  end
end
