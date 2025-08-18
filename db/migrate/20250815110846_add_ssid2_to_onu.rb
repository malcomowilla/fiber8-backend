class AddSsid2ToOnu < ActiveRecord::Migration[7.2]
  def change
    add_column :onus, :ssid2, :string
  end
end
