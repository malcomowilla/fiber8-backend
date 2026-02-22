class AddMerchantRequestIdToHotspotVoucher < ActiveRecord::Migration[7.2]
  def change
    add_column :hotspot_vouchers, :merchant_request_id, :string
  end
end
