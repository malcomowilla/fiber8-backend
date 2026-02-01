class AddSmsSentToHotspotVoucher < ActiveRecord::Migration[7.2]
  def change
    add_column :hotspot_vouchers, :sms_sent, :boolean, default: false
  end
end
