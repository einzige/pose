#
# Polymorphic search for ActiveRecord objects.
#
module Pose
  extend ActiveSupport::Concern

  # By default, doesn't run in tests.
  # Set this to true to test the search functionality.
  CONFIGURATION = { :search_in_tests => false }

  included do
    has_many :pose_assignments, :as => :posable
    has_many :pose_words, :through => :pose_assignments

    after_save :change_pose_words
    before_destroy :delete_pose_words
  end
  
  module ClassMethods

    def stored_block= value
      @stored_block = value
    end
    
    def stored_block
      @stored_block
    end
    
    # Returns all objects matching the given query.
    def search query
      ids = {}
      query.split(' ').each do |query_word|
        WordAssignment.joins(:word) \
                      .where(:words => {:text.matches => "#{query_word}%"}) \
                      .each do |word_assignment|
          ids[word_assignment.wordable_type] = [] unless ids[word_assignment.wordable_type]
          ids[word_assignment.wordable_type] << word_assignment.wordable_id
        end
      end

      result = {}
      ids.each do |key, value|
        my_class = Kernel.const_get(key)
        sym = key.downcase.pluralize.to_sym
        result[sym] = my_class.where :id => value
      end
      result
    end
  end

  module InstanceMethods
    
    # Updates the associated words for this object in the database.
    def change_pose_words

      # Don't do this in tests.
      return if Rails.env == 'test' and !CONFIGURATION[:search_in_tests]

      update_pose_words
    end

    # Removes this objects from the search index.
    def delete_pose_words
      return if Rails.env == 'test' and !CONFIGURATION[:search_in_tests]
      self.words.clear
    end

    # Helper method.
    # Updates the search words with the text returned by search_strings.
    def update_pose_words
      new_words = []
      search_strings = self.pose_content
      search_strings.flatten.each do |text|
        next unless text
        text.to_s.split(' ').each do |word|
          new_words.concat Pose.root_word(word)
        end
      end
      new_words.uniq!

      # Remove now obsolete words from search index.
      Pose.get_words_to_remove(self.pose_words, new_words).each do |word_to_remove|
        self.pose_words.delete word_to_remove
      end

      # Add new words to the search index.
      Pose.get_words_to_add(self.pose_words, new_words).each do |word_to_add|
        self.pose_words << PoseWord.find_or_create_by_text(word_to_add)
      end
    end
  end

  # Helper method.
  # Returns all strings that are in new_words, but not in existing_words.
  def Pose.get_words_to_add existing_words, new_words
    new_words - existing_words.map(&:text)
  end

  # Helper method.
  # Returns the id of all word objects that are in existing_words, but not in new_words.
  def Pose.get_words_to_remove existing_words, new_words
    existing_words.map do |existing_word|
      new_words.include?(existing_word.text) ? nil : existing_word
    end.compact
  end
  
  def Pose.is_url word
    uri = URI::parse word
    return uri.scheme == 'http'
  rescue URI::InvalidURIError
    false
  end
  
  # Reduces the given word to it's search form.
  def Pose.root_word raw_word
    result = []
    raw_word_copy = raw_word[0..-1]
    raw_word_copy.gsub! /[()*<>'",;]/, ' '
    raw_word_copy.gsub! /\s+/, ' '
    raw_word_copy.split(' ').each do |word|
      if Pose.is_url(word)
        result.concat word.split(/[\.\/\:]/).delete_if{|word| word.blank?}
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
  
end


def posify
  include Pose
end
