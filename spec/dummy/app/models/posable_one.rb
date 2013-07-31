class PosableOne < ActiveRecord::Base
  belongs_to :user

  posify { text }
end
