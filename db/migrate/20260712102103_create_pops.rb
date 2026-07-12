class CreatePops < ActiveRecord::Migration[7.2]
  def change
    create_table :pops do |t|
      t.string :name
      t.decimal :lat, precision: 10, scale: 6
      t.decimal :lng, precision: 10, scale: 6
      t.string :address
      t.string :status
      t.integer :account_id
      t.text :description

      t.timestamps
    end
  end
end
