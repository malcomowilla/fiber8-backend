class CreateHotspotTemplates < ActiveRecord::Migration[7.2]
  def change
    create_table :hotspot_templates do |t|
      t.string :name
      t.integer :account_id
      t.string :preview_image

      t.timestamps
    end
  end
end
