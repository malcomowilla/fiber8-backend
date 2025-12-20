class AddPremiumToHotspotTemplate < ActiveRecord::Migration[7.2]
  def change
    add_column :hotspot_templates, :premium, :boolean
  end
end
