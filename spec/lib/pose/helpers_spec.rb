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


end
