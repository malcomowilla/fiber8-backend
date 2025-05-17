class AddEnable2FaGoogleAuthToAdminSettings < ActiveRecord::Migration[7.2]
  def change
    add_column :admin_settings, :enable_2fa_google_auth, :boolean, default: false
  end
end





