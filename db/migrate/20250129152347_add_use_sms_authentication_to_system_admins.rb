class AddUseSmsAuthenticationToSystemAdmins < ActiveRecord::Migration[7.1]
  def change
    add_column :system_admins, :use_sms_authentication, :boolean, default: false
  end
end
