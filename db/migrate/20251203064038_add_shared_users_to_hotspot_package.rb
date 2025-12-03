class AddSharedUsersToHotspotPackage < ActiveRecord::Migration[7.2]
  def change
    add_column :hotspot_packages, :shared_users, :string
  end
end
