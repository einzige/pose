include Rake::DSL
namespace :pose do

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
  
  desc "Removes the search index for all instances of the given classes."
  task :remove_from_index, [:class_name] => :environment do |t, args|
    clazz = Kernel.const_get args.class_name
    PoseAssignment.cleanup_class_index clazz
    puts "Search index for class #{clazz.name} deleted.\n\n"
  end
end
