namespace :pose do

  desc "Explaining what the task does"
  task :reindex_all, [:class_name] => :environment do
    clazz = Kernel.const_get class_name
    clazz.find_each do |instance|
      instance.update_pose_words
    end
  end
  
  desc "Removes the search index for the given classes"
  task :remove_from_index, [:class_name] => :environment do
    clazz = Kernel.const_get class_name
    clazz.find_each do |instance|
      instance.delete_pose_words
    end
  end
end