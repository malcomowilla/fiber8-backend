class AddLocationToHotspotTemplate < ActiveRecord::Migration[7.2]
  def change
    add_column :hotspot_templates, :location, :string
  end
end
