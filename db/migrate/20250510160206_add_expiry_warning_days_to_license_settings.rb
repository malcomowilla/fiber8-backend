class AddExpiryWarningDaysToLicenseSettings < ActiveRecord::Migration[7.2]
  def change
    add_column :license_settings, :expiry_warning_days, :integer
  end
end
