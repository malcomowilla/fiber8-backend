class CreateSmsProviderSettings < ActiveRecord::Migration[7.2]
  def change
    create_table :sms_provider_settings do |t|
      t.string :sms_provider

      t.timestamps
    end
  end
end
