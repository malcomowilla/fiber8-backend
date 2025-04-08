class CreateIpNetworks < ActiveRecord::Migration[7.2]
  def change
    create_table :ip_networks do |t|
      t.string :network
      t.string :title
      t.string :ip_adress
      t.string :subnet_mask
      t.integer :account_id

      t.timestamps
    end
  end
end
