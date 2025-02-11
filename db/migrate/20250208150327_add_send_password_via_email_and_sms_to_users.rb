class AddSendPasswordViaEmailAndSmsToUsers < ActiveRecord::Migration[7.2]
  def change
    add_column :users, :send_password_via_sms, :boolean, default: false
    add_column :users, :send_password_via_email, :boolean, default: false
  end
end
