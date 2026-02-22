class AddCheckOutRequestIdToHotspotVoucher < ActiveRecord::Migration[7.2]
  def change
    add_column :hotspot_vouchers, :checkout_request_id, :string
    add_column :hotspot_vouchers, :payment_status, :string
  end
end
