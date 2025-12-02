class AddSmsSentAtVoucherToHotspotVoucher < ActiveRecord::Migration[7.2]
  def change
    add_column :hotspot_vouchers, :sms_sent_at_voucher, :datetime
  end
end




