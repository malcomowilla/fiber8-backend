class AddIndexToFramedIpAddressRadAcct < ActiveRecord::Migration[7.2]
  def change
    add_index :radacct, :framedprotocol
    add_index :radacct, :framedipaddress
    add_index :radacct, :callingstationid
  end
end
