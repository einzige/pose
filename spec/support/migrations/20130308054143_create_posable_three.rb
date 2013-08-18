class CreatePosableThree < ActiveRecord::Migration
  def change
    create_table :posable_threes do |t|
      t.string :text_1
      t.string :text_2
    end
  end
end

