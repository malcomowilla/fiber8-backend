class AddAccountIdToSmsSettings < ActiveRecord::Migration[7.1]
  def change
    add_column :sms_settings, :account_id, :integer
  end
end
