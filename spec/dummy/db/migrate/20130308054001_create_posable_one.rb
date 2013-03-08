class CreatePosableOne < ActiveRecord::Migration
  def change
    create_table :posable_ones do |t|
      t.string :text
      t.boolean :private
    end
  end
end
