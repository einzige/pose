require 'ruby-progressbar'

module Pose
  module Jobs
    class Vacuum
      def perform
        puts "Cleaning Pose search index...\n\n"

        progress_bar = ProgressBar.create title: '  assignments', total: Pose::Assignment.count
        Pose::Assignment.cleanup_orphaned_pose_assignments progress_bar
        progress_bar.finish

        progress_bar = ProgressBar.create title: '  words', total: Pose::Word.count
        Pose::Word.remove_unused_words progress_bar
        progress_bar.finish

        puts "\nPose search index cleanup complete.\n\n"
      end
    end
  end
end