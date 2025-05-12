class AddAccountIIdAndPhoneNumberToLicenseSettings < ActiveRecord::Migration[7.2]
  def change
    add_column :license_settings, :phone_number, :string
    add_column :license_settings, :account_id, :integer
  end
end
