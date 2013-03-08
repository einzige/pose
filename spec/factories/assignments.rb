FactoryGirl.define do

  factory :assignment, class: Pose::Assignment do
    word
    posable factory: :posable_one
  end

end
