class AddPhoneNumberAndPhoneVerifiedToSystemAdmins < ActiveRecord::Migration[7.1]
  def change
    add_column :system_admins, :system_admin_phone_number_verified, :boolean, default: false
    add_column :system_admins, :system_admin_phone_number, :string
  end
end



