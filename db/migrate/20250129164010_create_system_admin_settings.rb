class CreateSystemAdminSettings < ActiveRecord::Migration[7.1]
  def change
    create_table :system_admin_settings do |t|
      t.boolean :login_with_passkey
      t.boolean :use_sms_authentication, default: false
      t.boolean :use_email_authentication, default: false
      t.integer :system_admin_id

      t.timestamps
    end
  end
end
