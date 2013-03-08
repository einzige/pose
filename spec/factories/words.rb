FactoryGirl.define do

  factory :word, class: Pose::Word do
    text { Faker::Lorem.words(1).first }
  end

end
