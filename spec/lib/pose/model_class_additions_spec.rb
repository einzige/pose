require 'spec_helper'


describe Pose::ModelClassAdditions do
  subject { create :posable_one, text: 'one two'  }
  let(:instance_2) { create :posable_one, text: 'two three four' }


  it 'extends AR models' do
    expect(subject).to be_a_kind_of described_class
  end


  describe 'creating an instance' do
    it 'adds the instance data to the search index' do
      expect(Pose::Assignment).to have(0).instances
      expect(Pose::Word).to have(0).instances
      subject
      expect(Pose::Assignment).to have(2).instances
      expect(Pose::Word).to have(2).instances
    end
  end

  describe 'updating an instance' do
    it 'updates the instance data in the search index' do
      subject.text = 'two three four'
      subject.save!
      expect(subject).to have(3).pose_words
      expect(Pose::Assignment).to have(3).instances
    end
  end

  describe 'deleting an instance' do
    it 'removes the instance data from the search index' do
      subject ; instance_2
      subject.destroy
      expect(Pose::Assignment).to have(3).instances
    end
  end


  describe '#pose_current_words' do
    it 'returns all currently indexed words the instance' do
      expect(subject.pose_current_words).to match_array %w[one two]
    end
  end


  describe '#pose_fetch_content' do

    context 'pristine object' do
      it 'returns the searchable text snippet for this instance' do
        expect(subject.pose_fetch_content).to eql 'one two'
      end
    end

    context 'object with unsaved changes' do
      it 'returns the new unsaved searchable text' do
        subject.text = 'two three'
        expect(subject.pose_fetch_content).to eql 'two three'
      end
    end
  end


  describe '#pose_fresh_words' do

    context 'pristine object' do
      it 'returns the words that this instance should have based on its current content' do
        expect(subject.pose_fresh_words).to match_array %w[one two]
      end
    end

    context 'after a content change in the instance' do
      it 'returns only the current words' do
        subject.text = 'two three'
        expect(subject.pose_fresh_words true).to match_array %w[two three]
      end
    end

    describe 'reload parameter' do
      before :each do
        subject.pose_fresh_words
        subject.text = 'new text'
      end

      context 'given nothing' do
        it 'caches the data' do
          expect(subject.pose_fresh_words).to match_array %w[one two]
        end
      end

      context 'given false' do
        it 'caches the data' do
          expect(subject.pose_fresh_words false).to match_array %w[one two]
        end
      end

      context 'given true' do
        it 'always recalculates the data' do
          expect(subject.pose_fresh_words true).to match_array %w[new text]
        end
      end
    end
  end


  describe 'pose_stale_words' do

    context 'pristine object' do
      it 'has no stale words' do
        expect(subject.pose_stale_words).to be_empty
      end
    end

    context 'object with unsaved changes' do
      it 'returns the words that have to be removed from the search index' do
        subject.text = 'two three'
        expect(subject.pose_stale_words true).to match_array %w[one]
      end
    end
  end


  describe 'pose_words_to_add' do

    context 'pristine object' do
      it 'has no words to add' do
        expect(subject.pose_words_to_add).to be_empty
      end
    end

    context 'object with unsaved changes' do
      it 'returns the words that are missing in the search index for this instance' do
        subject.text = 'two three'
        expect(subject.pose_words_to_add true).to match_array %w[three]
      end
    end
  end


  describe 'delete_pose_index' do
    it 'removes the search index for this instance' do
      subject ; instance_2
      expect(Pose::Assignment).to have(5).instances
      subject.delete_pose_index
      expect(Pose::Assignment).to have(3).instances
    end
  end
end
