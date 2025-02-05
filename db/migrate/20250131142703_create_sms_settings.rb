class CreateSmsSettings < ActiveRecord::Migration[7.1]
  def change
    create_table :sms_settings do |t|
      t.string :api_key
      t.string :api_secret
      t.string :sender_id
      t.string :short_code
      t.string :username
      t.integer :accoun_id

      t.timestamps
    end
  end
end
