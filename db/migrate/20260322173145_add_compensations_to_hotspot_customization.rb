class AddCompensationsToHotspotCustomization < ActiveRecord::Migration[7.2]
  def change
    add_column :hotspot_customizations, :enable_compensation, :boolean
    add_column :hotspot_customizations, :compensation_minutes, :string
    add_column :hotspot_customizations, :compensation_hours, :string
  end
end
