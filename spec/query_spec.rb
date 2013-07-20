# encoding: utf-8
require "spec_helper"

describe Pose::Query do

  subject { Pose::Query.new [PosableOne, [PosableTwo]], 'query string' }

  describe :initialize do

    it 'flattens the given classes' do
      expect(subject.classes).to eql [PosableOne, PosableTwo]
    end

  end

  describe :class_names do

    it 'returns the names of the given classes' do
      expect(subject.class_names).to eql ['PosableOne', 'PosableTwo']
    end
  end

end
