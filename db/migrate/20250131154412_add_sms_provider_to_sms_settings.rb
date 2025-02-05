class AddSmsProviderToSmsSettings < ActiveRecord::Migration[7.1]
  def change
    add_column :sms_settings, :sms_provider, :string
  end
end
