class CreateLicenseSettings < ActiveRecord::Migration[7.2]
  def change
    create_table :license_settings do |t|
      t.string :expiry_warning_days

      t.timestamps
    end
  end
end
