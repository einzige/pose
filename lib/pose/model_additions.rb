# Additions to posified ActiveRecord models.
module Pose
  module ModelAdditions
    extend ActiveSupport::Concern

    included do
      has_many :pose_assignments, as: :posable, dependent: :delete_all
      has_many :pose_words, through: :pose_assignments

      after_save :update_pose_index
      before_destroy :delete_pose_index

      cattr_accessor :pose_content
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
end
