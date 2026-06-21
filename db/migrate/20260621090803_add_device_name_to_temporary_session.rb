class AddDeviceNameToTemporarySession < ActiveRecord::Migration[7.2]
  def change
    add_column :temporary_sessions, :device_name, :string
  end
end
