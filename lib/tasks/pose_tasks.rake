include Rake::DSL if defined?(Rake::DSL)
require 'ruby-progressbar'

namespace :pose do

  desc "Cleans out unused data from the search index."
  task :vacuum => :environment do |t, args|
    puts "Cleaning Pose search index ...\n\n"
    progress_bar = ProgressBar.create title: '  assignments', total: Pose::Assignment.count
    Pose::Assignment.cleanup_orphaned_pose_assignments progress_bar
    progress_bar.finish

    progress_bar = ProgressBar.create title: '  words', total: Pose::Word.count
    Pose::Word.remove_unused_words progress_bar
    progress_bar.finish

    puts "\nPose search index cleanup complete.\n\n"
  end

  desc "Removes the search index for all instances of the given classes."
  task :remove, [:class_name] => :environment do |t, args|
    clazz = args.class_name.constantize
    Pose::Assignment.delete_class_index clazz
    puts "Search index for class #{clazz.name} deleted.\n\n"
  end

  desc "Deletes and recreates the search index for all instances of the given class."
  task :reindex_all, [:class_name] => [:environment] do |t, args|
    clazz = args.class_name.constantize
    progress_bar = ProgressBar.create title: "  reindexing", total: clazz.count
    clazz.find_each do |instance|
      instance.update_pose_words
      progress_bar.increment
    end
    progress_bar.finish
  end

end
