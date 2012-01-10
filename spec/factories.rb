Factory.define :pose_word do |word|
  word.text { Faker::Lorem.words(1).first }
end

Factory.define :pose_assignment do |assignment|
  assignment.association :pose_word
  assignment.association :posable, :factory => :posable_one
end

Factory.define :posable_one do |posable|
  posable.text { Faker::Lorem.words(3).join ' ' }
end
