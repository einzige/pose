FactoryGirl.define do

  factory :posable_one do
    text { Faker::Lorem.words(2).join ' ' }
  end

end
