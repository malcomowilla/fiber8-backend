class AddPepeaToHotspotTemplate < ActiveRecord::Migration[7.2]
  def change
    add_column :hotspot_templates, :pepea, :boolean
  end
end
