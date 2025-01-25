class AddOtpToSystemAdmins < ActiveRecord::Migration[7.1]
  def change
    add_column :system_admins, :otp, :string
  end
end
