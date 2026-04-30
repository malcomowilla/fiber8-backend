class AddTenantIdToSmsSetting < ActiveRecord::Migration[7.2]
  def change
    add_column :sms_settings, :tenant_id, :integer
  end
end
