class CreateHotspotPlans < ActiveRecord::Migration[7.2]
  def change
    create_table :hotspot_plans do |t|
      t.string :name
      t.string :hotspot_subscribers

      t.timestamps
    end
  end
end
