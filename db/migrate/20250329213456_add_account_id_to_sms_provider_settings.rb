class AddAccountIdToSmsProviderSettings < ActiveRecord::Migration[7.2]
  def change
    add_column :sms_provider_settings, :account_id, :integer
  end
end
