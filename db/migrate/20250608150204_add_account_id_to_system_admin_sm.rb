class AddAccountIdToSystemAdminSm < ActiveRecord::Migration[7.2]
  def change
    add_column :system_admin_sms, :account_id, :integer
  end
end
