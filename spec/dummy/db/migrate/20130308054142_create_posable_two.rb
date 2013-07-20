class CreatePosableTwo < ActiveRecord::Migration
  def change
    create_table :posable_twos do |t|
      t.string :text
      t.boolean :private
      t.integer :user_id
    end
  end
end

