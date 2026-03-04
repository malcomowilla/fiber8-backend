class AddIndexToIpPaidConnectedHotspotPackageVoucherCodePhoneNumberMacTemporarySession < ActiveRecord::Migration[7.2]
  def change
    add_index :temporary_sessions, :ip
    add_index :temporary_sessions, :mac
    add_index :temporary_sessions, :phone_number
    add_index :temporary_sessions, :voucher_code
    add_index :temporary_sessions, :connected
    add_index :temporary_sessions, :paid
    add_index :temporary_sessions, :hotspot_package
    add_index :temporary_sessions, :status


  end
end
