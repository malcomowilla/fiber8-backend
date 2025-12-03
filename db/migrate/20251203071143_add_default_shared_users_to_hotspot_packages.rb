class AddDefaultSharedUsersToHotspotPackages < ActiveRecord::Migration[7.2]
  def change
        change_column_default :hotspot_packages, :shared_users, from: nil, to: "1"

  end
end
