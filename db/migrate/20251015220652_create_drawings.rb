class CreateDrawings < ActiveRecord::Migration[7.2]
  def change
    create_table :drawings do |t|
      t.string :type
      t.json :position
      t.json :path
      t.json :paths
      t.json :center
      t.json :bounds
       t.integer :account_id

      t.timestamps
    end
  end
end
