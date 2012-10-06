# Verifies that a posable object has the given pose words in its search index.
RSpec::Matchers.define :have_pose_words do |expected|

  match do |actual|
    actual.should have(expected.size).pose_words
    texts = actual.pose_words.map &:text
    expected.each do |expected_word|
      # Note (KG): Can't use text.should include(expected_word) here
      #            because Ruby thinks I want to include a Module for some reason.
      texts.include?(expected_word).should be_true
    end
  end

  failure_message_for_should do |actual|
    texts = actual.pose_words.map &:text
    "expected that subject would have pose words [#{expected.join ', '}], but it has [#{texts.join ', '}]"
  end

end

