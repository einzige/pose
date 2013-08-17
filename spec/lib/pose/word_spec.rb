require 'spec_helper'

module Pose
  describe Word do
    describe 'class methods' do
      context 'with a SQL database' do
        before :each do
          Helpers.should_receive(:is_sql_database?).and_return(true)
        end

        it_should_behave_like 'cleans unused words'
      end

      context 'without a SQL database' do
        before :each do
          Helpers.should_receive(:is_sql_database?).and_return(false)
        end

        it_should_behave_like 'cleans unused words'
      end
    end
  end
end
