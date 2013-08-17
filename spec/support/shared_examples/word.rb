shared_examples 'cleans unused words' do
  it 'removes unused words' do
    FactoryGirl.create :word
    Pose::Word.remove_unused_words
    expect(Pose::Word.count).to eql 0
  end

  it 'does not remove used words' do
    FactoryGirl.create :posable_one
    Pose::Word.remove_unused_words
    expect(Pose::Word.count).to be > 0
  end
end