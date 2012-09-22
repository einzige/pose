FactoryGirl.define do

  factory :pose_word do
    text { Faker::Lorem.words(1).first }
  end

  factory :pose_assignment do
    pose_word
    posable factory: :posable_one
  end

  factory :posable_one do
    text { Faker::Lorem.words(3).join ' ' }
  end
end
