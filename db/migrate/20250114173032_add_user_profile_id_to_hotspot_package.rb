class AddUserProfileIdToHotspotPackage < ActiveRecord::Migration[7.1]
  def change
    add_column :hotspot_packages, :user_profile_id, :string
  end
end
