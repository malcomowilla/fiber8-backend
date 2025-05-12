class RemoveExpiryWarningDaysFromLicenseSettings < ActiveRecord::Migration[7.2]
  def change
    remove_column :license_settings, :expiry_warning_days, :string
  end
end
