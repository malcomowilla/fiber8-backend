class AddSsidToOnu < ActiveRecord::Migration[7.2]
  def change
    add_column :onus, :ssid1, :string
  end
end
