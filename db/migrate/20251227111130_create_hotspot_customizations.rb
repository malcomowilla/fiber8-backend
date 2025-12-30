class CreateHotspotCustomizations < ActiveRecord::Migration[7.2]
  def change
    create_table :hotspot_customizations do |t|
      t.boolean :customize_template_and_package_per_location
      t.integer :account_id

      t.timestamps
    end
  end
end
