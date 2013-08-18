# Additions to posified ActiveRecord classes.
module Pose
  module ModelClassAdditions
    extend ActiveSupport::Concern

    included do
      has_many :pose_assignments, class_name: 'Pose::Assignment', as: :posable, dependent: :delete_all
      has_many :pose_words, through: :pose_assignments, class_name: 'Pose::Word', source: :word

      after_save :update_pose_index
      before_destroy :delete_pose_index

      cattr_accessor :pose_content
    end

    # Resets the cache for fresh words.
    # This happens automatically with normal usage of Pose.
    # This method makes testing easier.
    def clear_fresh_word_cache
      @pose_fresh_words = nil
    end

    # Returns all words in the search index for this instance.
    # @return [Array<String>]
    def pose_current_words
      pose_words.map(&:text)
    end

    # Returns the searchable text snippet for this instance.
    # This data is not stored in the search engine.
    # It is recomputes this from data in the database here.
    # @return [String]
    def pose_fetch_content
      instance_eval(&(pose_content)).to_s
    end

    # @return [Array<String>]
    def pose_fresh_words
      @pose_fresh_words ||= Query.query_words pose_fetch_content
    end

    # @return [Array<String>]
    def pose_stale_words
      pose_current_words - pose_fresh_words
    end

    # @return [Array<String>]
    def pose_words_to_add
      pose_fresh_words - pose_current_words
    end

    # Updates the associated words for this object in the database.
    def update_pose_index
      update_pose_words if Pose.perform_search?
    end

    # Removes this objects from the search index.
    def delete_pose_index
      self.pose_words.clear if Pose.perform_search?
    end

    # Helper method.
    # Updates the search words with the text returned by search_strings.
    def update_pose_words
      clear_fresh_word_cache
      self.pose_words.delete(Word.factory(pose_stale_words))
      self.pose_words << Word.factory(pose_words_to_add)
    end
  end
end
