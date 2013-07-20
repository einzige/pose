class PosableOne < ActiveRecord::Base
  attr_accessible :text

  belongs_to :user

  posify { text }
end
