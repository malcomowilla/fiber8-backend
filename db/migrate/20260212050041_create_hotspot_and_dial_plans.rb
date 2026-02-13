class CreateHotspotAndDialPlans < ActiveRecord::Migration[7.2]
  def change
    create_table :hotspot_and_dial_plans do |t|
      t.datetime :expiry
      t.string :status
      t.integer :expiry_days
      t.string :company_name
      t.string :name

      t.timestamps
    end
  end
end
