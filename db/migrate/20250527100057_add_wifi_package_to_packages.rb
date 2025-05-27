class AddWifiPackageToPackages < ActiveRecord::Migration[7.2]
  def change
    add_column :packages, :wifi_package, :string
  end
end
