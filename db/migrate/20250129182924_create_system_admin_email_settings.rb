class CreateSystemAdminEmailSettings < ActiveRecord::Migration[7.1]
  def change
    create_table :system_admin_email_settings do |t|
      t.string :smtp_host
      t.string :smtp_username
      t.string :sender_email
      t.string :smtp_password
      t.string :api_keydomain
      t.integer :system_admin_id

      t.timestamps
    end
  end
end
