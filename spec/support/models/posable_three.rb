class PosableThree < ActiveRecord::Base
  posify :text_1, :text_2, :generate_custom_text do
    "|from pose block|"
  end

  # @return [String]
  def generate_custom_text
    "|custom text|"
  end
end
