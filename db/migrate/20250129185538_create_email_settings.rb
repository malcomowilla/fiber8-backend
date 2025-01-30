class CreateEmailSettings < ActiveRecord::Migration[7.1]
  def change
    create_table :email_settings do |t|
      t.string :smtp_host
      t.string :smtp_username
      t.string :sender_email
      t.string :smtp_password
      t.string :api_key
      t.string :domain

      t.timestamps
    end
  end
end
