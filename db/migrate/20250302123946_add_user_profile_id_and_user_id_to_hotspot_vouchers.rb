class AddUserProfileIdAndUserIdToHotspotVouchers < ActiveRecord::Migration[7.2]
  def change
    add_column :hotspot_vouchers, :user_manager_user_id, :string
    add_column :hotspot_vouchers, :user_profile_id, :string
  end
end
