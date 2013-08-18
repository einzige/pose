FactoryGirl.define do

  factory :posable_three do
    text_1 { Faker::Lorem.words(2).join ' ' }
    text_2 { Faker::Lorem.words(2).join ' ' }
  end

end
