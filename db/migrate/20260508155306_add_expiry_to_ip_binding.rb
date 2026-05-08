class AddExpiryToIpBinding < ActiveRecord::Migration[7.2]
  def change
    add_column :ip_bindings, :expiry, :datetime
  end
end
