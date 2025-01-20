class CreateClientMacAdresses < ActiveRecord::Migration[7.1]
  def change
    create_table :client_mac_adresses do |t|
      t.string :macadress

      t.timestamps
    end
  end
end
