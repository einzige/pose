class User < ActiveRecord::Base
  has_many :posable_one
  has_many :posable_two
end
