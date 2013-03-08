class PosableOne < ActiveRecord::Base
  attr_accessible :text

  posify { text }
end
