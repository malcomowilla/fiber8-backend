class CreateTvPlans < ActiveRecord::Migration[7.2]
   def change
    create_table :tv_plans do |t|
      t.references :account, null: false, foreign_key: true
      t.string  :name, null: false
      t.decimal :price, precision: 10, scale: 2, default: 0
      t.integer :validity
      t.string  :validity_period_units, default: "hours" # minutes | hours | days
      t.integer :download_limit
      t.integer :upload_limit
      t.string :nas_router
      t.boolean :active, default: true
      t.integer :position, default: 0
      t.timestamps
      end
    end
end
