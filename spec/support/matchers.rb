# Verifies that a posable object has the given pose words in its search index.
RSpec::Matchers.define :have_pose_words do |expected|

  match do |actual|
    actual.pose_words.map(&:text).sort == expected.sort
  end

  failure_message_for_should do |actual|
    texts = actual.pose_words.map &:text
    "expected that subject would have pose words [#{expected.join ', '}], but it has [#{texts.join ', '}]"
  end
end

