namespace :pose do

  desc "Deletes and recreates the search index for all instances of the given class."
  task :reindex_all, [:class_name] => :environment do
    clazz = Kernel.const_get class_name
    clazz.find_each do |instance|
      instance.update_pose_words
    end
  end
  
  desc "Removes the search index for all instances of the given classes"
  task :remove_from_index, [:class_name] => :environment do
    clazz = Kernel.const_get class_name
    clazz.find_each do |instance|
      instance.delete_pose_words
    end
  end
end