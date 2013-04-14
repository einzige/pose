module Pose
  class Query
    attr_reader :classes, :query_string

    # @param [Array<Class>] classes
    # @param [String] query_string
    def initialize(classes, query_string)
      @classes = [classes].flatten
      @query_string = query_string
    end

    # @return [Array<String>]
    def class_names
      classes.map &:name
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
  end
end