class AddProviderToSystemAdminSm < ActiveRecord::Migration[7.2]
  def change
    add_column :system_admin_sms, :sms_provider, :string
  end
end
