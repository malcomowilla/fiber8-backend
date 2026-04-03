class AddTenantIdToHotspotMpesaSetting < ActiveRecord::Migration[7.2]
  def change
    add_column :hotspot_mpesa_settings, :tenant_id, :integer
  end
end
