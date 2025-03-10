class AddEmailToHotspotSettings < ActiveRecord::Migration[7.2]
  def change
    add_column :hotspot_settings, :email, :string
  end
end
