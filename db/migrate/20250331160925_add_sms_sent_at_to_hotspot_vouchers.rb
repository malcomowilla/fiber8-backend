class AddSmsSentAtToHotspotVouchers < ActiveRecord::Migration[7.2]
  def change
    add_column :hotspot_vouchers, :sms_sent_at, :datetime
  end
end
