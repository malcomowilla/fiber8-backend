class AddWanIpAndMacToOnu < ActiveRecord::Migration[7.2]
  def change
    add_column :onus, :wan_ip, :string
    add_column :onus, :mac_adress, :string
  end
end
