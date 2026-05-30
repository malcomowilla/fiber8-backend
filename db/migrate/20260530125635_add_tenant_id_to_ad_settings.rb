class AddTenantIdToAdSettings < ActiveRecord::Migration[7.2]
  def change
    add_column :ad_settings, :tenant_id, :integer
  end
end
