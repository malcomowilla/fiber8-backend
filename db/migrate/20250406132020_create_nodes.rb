class CreateNodes < ActiveRecord::Migration[7.2]
  def change
    create_table :nodes do |t|
      t.string :name
      t.string :latitude
      t.string :longitude

      t.timestamps
    end
  end
end
