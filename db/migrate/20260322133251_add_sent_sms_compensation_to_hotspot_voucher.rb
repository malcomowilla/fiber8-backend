class AddSentSmsCompensationToHotspotVoucher < ActiveRecord::Migration[7.2]
  def change
    add_column :hotspot_vouchers, :sent_sms_compensation, :boolean, default: false
  end
end
