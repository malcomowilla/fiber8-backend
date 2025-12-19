class AddVoucherTypeToHotspotSettings < ActiveRecord::Migration[7.2]

  
  def change
        add_column :hotspot_settings, :voucher_type, :string, default: 'Mixed'
  end
end






