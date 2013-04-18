FactoryGirl.define do
  factory :posable_two do
    text { Faker::Lorem.words(2).join ' ' }
  end
end
