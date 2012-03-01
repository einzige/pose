include Rake::DSL if defined?(Rake::DSL)
require 'progressbar'
namespace :pose do

  desc "Cleans out unused data from the search index."
  task :cleanup_index => :environment do |t, args|
    puts "Cleaning Pose search index ...\n\n"
    progress_bar = ProgressBar.new '  assignments', PoseAssignment.count
    PoseAssignment.cleanup_orphaned_pose_assignments progress_bar
    progress_bar.finish

    progress_bar = ProgressBar.new '  words', PoseWord.count
    PoseWord.remove_unused_words progress_bar
    progress_bar.finish

    puts "\nPose search index cleanup complete.\n\n"
  end

  desc "Removes the search index for all instances of the given classes."
  task :delete_index, [:class_name] => :environment do |t, args|
    clazz = Kernel.const_get args.class_name
    PoseAssignment.cleanup_class_index clazz
    puts "Search index for class #{clazz.name} deleted.\n\n"
  end

  desc "Deletes and recreates the search index for all instances of the given class."
  task :reindex_all, [:class_name] => [:environment] do |t, args|
    clazz = Kernel.const_get args.class_name
    progress_bar = ProgressBar.new "  reindexing", clazz.count
    clazz.find_each do |instance|
      instance.update_pose_words
      progress_bar.inc
    end
    progress_bar.finish
  end
  
end
