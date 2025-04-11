class AddNasToIpNetworks < ActiveRecord::Migration[7.2]
  def change
    add_column :ip_networks, :nas, :string
  end
end
