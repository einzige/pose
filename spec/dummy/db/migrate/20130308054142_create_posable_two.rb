class CreatePosableTwo < ActiveRecord::Migration
  def change
    create_table :posable_twos do |t|
      t.string :text
      t.boolean :private
    end
  end
end

