class AddDeviceToTemporarySession < ActiveRecord::Migration[7.2]
  def change
    add_column :temporary_sessions, :device_mac, :string
    add_column :temporary_sessions, :device_type, :string
    add_column :temporary_sessions, :payment_type, :string
  end
end
