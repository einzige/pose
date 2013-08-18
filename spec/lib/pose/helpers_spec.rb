# encoding: utf-8
require "spec_helper"


describe Pose::Helpers do

  describe :is_sql_database? do

    it 'recognizes postgres databases' do
      ActiveRecord::Base.connection.class.stub(:name).and_return 'ActiveRecord::ConnectionAdapters::PostgreSQLAdapter'
      expect(Pose::Helpers.is_sql_database?).to be_true
    end

    it 'recognizes sqlite3 databases' do
      ActiveRecord::Base.connection.class.stub(:name).and_return 'ActiveRecord::ConnectionAdapters::SQLite3Adapter'
      expect(Pose::Helpers.is_sql_database?).to be_true
    end
  end


  describe :make_array do

    it 'converts a single value into an array' do
      expect(Pose::Helpers.make_array(1)).to eq [1]
    end

    it 'leaves arrays as arrays' do
      expect(Pose::Helpers.make_array([1])).to eq [1]
    end

    it 'flattens nested arrays' do
      Pose::Helpers.make_array([1, [2], [[3]]]).should eq [1, 2, 3]
    end
  end


end
