class AddSmtpPortToEmailSettings < ActiveRecord::Migration[7.1]
  def change
    add_column :email_settings, :smtp_port, :string
  end
end
