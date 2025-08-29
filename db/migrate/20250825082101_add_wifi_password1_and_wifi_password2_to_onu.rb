class AddWifiPassword1AndWifiPassword2ToOnu < ActiveRecord::Migration[7.2]
  def change
    add_column :onus, :wifi_password1, :string
    add_column :onus, :wifi_password2, :string
  end
end
