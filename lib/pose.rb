# Note (KG): Need to include the rake DSL here to prevent deprecation warnings in the Rakefile.
require 'rake'
include Rake::DSL


# Polymorphic search for ActiveRecord objects.
module Pose
  extend ActiveSupport::Concern

  # By default, doesn't run in tests.
  # Set this to true to test the search functionality.
  CONFIGURATION = { :search_in_tests => false }

  included do
    has_many :pose_assignments, :as => :posable, :dependent => :delete_all
    has_many :pose_words, :through => :pose_assignments

    after_save :update_pose_index
    before_destroy :delete_pose_index

    cattr_accessor :pose_content
  end

  # Asks if model should perform search.
  #
  # @return [false, true]
  def perform_search?
    !(Rails.env == 'test' and !CONFIGURATION[:search_in_tests])
  end

  module InstanceMethods
    
    # Updates the associated words for this object in the database.
    def update_pose_index
      update_pose_words if perform_search?
    end

    # Removes this objects from the search index.
    def delete_pose_index
      self.pose_words.clear if perform_search?
    end

    # Helper method.
    # Updates the search words with the text returned by search_strings.
    def update_pose_words

      # Step 1: get an array of all words for the current object.
      search_string = instance_eval &(self.class.pose_content)
      new_words = search_string.to_s.split(' ').map { |word| Pose.root_word(word) }.flatten.uniq

      # Step 2: Add new words to the search index.
      Pose.get_words_to_add(self.pose_words, new_words).each do |word_to_add|
        self.pose_words << PoseWord.find_or_create_by_text(word_to_add)
      end

      # Step 3: Remove now obsolete words from search index.
      Pose.get_words_to_remove(self.pose_words, new_words).each do |word_to_remove|
        self.pose_words.delete word_to_remove
      end
    end
  end

  class <<self

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
    # @param [Number?] limit Optional limit.
    #
    # @return [Hash<Class, ActiveRecord::Relation>]
    def search query, classes, limit = nil

      # Turn 'classes' into an array.
      classes = [classes].flatten
      classes_names = classes.map &:name
      classes_names = classes_names[0] if classes_names.size == 1

      # Get the ids of the results.
      result_classes_and_ids = {}
      query.split(' ').each do |query_word|
        current_word_classes_and_ids = {}
        classes.each { |clazz| current_word_classes_and_ids[clazz.name] = [] }
        query = PoseAssignment.joins(:pose_word) \
                              .where(:pose_words => {:text.matches => "#{query_word}%"},
                                     :posable_type => classes_names)
        query.each do |pose_assignment|
          current_word_classes_and_ids[pose_assignment.posable_type] << pose_assignment.posable_id
        end

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

          if ids.any? && classes.include?(result_class)
            ids = ids.slice(0, limit) if limit
            result[result_class] = result_class.where :id => ids
          else
            result[result_class] = []
          end
        end
      end
    end
  end
end


require 'pose/posifier'
require "pose/railtie" if defined? Rails
require 'pose_assignment'
require 'pose_word'
