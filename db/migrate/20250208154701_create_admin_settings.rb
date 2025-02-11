class CreateAdminSettings < ActiveRecord::Migration[7.2]
  def change
    create_table :admin_settings do |t|
      t.boolean :enable_2fa_for_admin_sms
      t.boolean :enable_2fa_for_admin_email
      t.boolean :send_password_via_sms
      t.boolean :send_password_via_email
      t.boolean :check_inactive_days
      t.boolean :check_inactive_hrs
      t.boolean :check_inactive_minutes
      t.boolean :enable_2fa_for_admin_passkeys
      t.integer :account_id
      t.integer :user_id

      t.timestamps
    end
  end
end
