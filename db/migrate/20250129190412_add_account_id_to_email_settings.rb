class AddAccountIdToEmailSettings < ActiveRecord::Migration[7.1]
  def change
    add_column :email_settings, :account_id, :integer
  end
end
