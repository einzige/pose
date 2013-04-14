module Pose
  class Query
    attr_reader :classes, :query

    def initialize(classes, query)
      @classes = [classes].flatten
      @query = query
    end

    def class_names
      classes.map &:name
    end

    # Gets the ids of the results.
    def result_classes_and_ids
      {}.tap do |classes_and_ids|
        Helpers.query_terms(query).each do |query_word|
          Helpers.search_classes_and_ids_for_word(query_word, class_names).each do |class_name, ids|
            Helpers.merge_search_result_word_matches classes_and_ids, class_name, ids
          end
        end
      end
    end
  end
end