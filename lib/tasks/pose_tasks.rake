namespace :pose do

  desc "Cleans out unused data from the search index."
  task :vacuum => :environment do
    Pose::Jobs::Vacuum.new.perform
  end

  desc "Removes the search index for all instances of the given classes."
  task :remove, [:class_name] => :environment do |_, args|
    Pose::Jobs::Remove.new(args.class_name).perform
  end

  desc "Deletes and recreates the search index for all instances of the given class."
  task :reindex_all, [:class_name] => [:environment] do |_, args|
    Pose::Jobs::ReindexAll.new(args.class_name).perform
  end
end
