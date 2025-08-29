class AddWlan1StatusEnable1RfBand1Standard1RadioEnabled1TotalAssociations1SsidAdvertismentEnabled1WpaEncryption1Channelwidth1Autochannel1Channel1CountryRegulatoDomain1TxPower1AuthenticationMode1ToOnu < ActiveRecord::Migration[7.2]
  def change
    add_column :onus, :wlan1_status, :string
    add_column :onus, :enable1, :boolean
    add_column :onus, :rf_band1, :string
    add_column :onus, :radio_enabled1, :boolean
    add_column :onus, :total_associations1, :string
    add_column :onus, :ssid_advertisment_enabled1, :boolean
    add_column :onus, :wpa_encryption1, :string
    add_column :onus, :channel_width1, :string
    add_column :onus, :autochannel1, :boolean
    add_column :onus, :channel, :string
    add_column :onus, :country_regulatory_domain1, :string
    add_column :onus, :tx_power1, :string
    add_column :onus, :authentication_mode1, :string
  end
end
