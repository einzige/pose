class CreatePosableOne < ActiveRecord::Migration
  def change
    create_table :posable_ones do |t|
      t.string :text
      t.boolean :private
      t.integer :user_id
    end
  end
end
