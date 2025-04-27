class AddMacAdressToRadCt < ActiveRecord::Migration[7.2]
  def change
    add_column :radacct, :mac_adress, :string
  end
end
