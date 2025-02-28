class AddWeekDaysToHotspotPackage < ActiveRecord::Migration[7.2]
  def change
    add_column :hotspot_packages, :weekdays, :string, array: true, default: []

  end
end
