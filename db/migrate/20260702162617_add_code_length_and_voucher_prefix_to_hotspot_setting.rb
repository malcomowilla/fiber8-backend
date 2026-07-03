class AddCodeLengthAndVoucherPrefixToHotspotSetting < ActiveRecord::Migration[7.2]
  def change
    add_column :hotspot_settings, :code_length, :string
    add_column :hotspot_settings, :voucher_prefix, :string
  end
end
