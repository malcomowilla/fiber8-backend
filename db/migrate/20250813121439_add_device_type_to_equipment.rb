class AddDeviceTypeToEquipment < ActiveRecord::Migration[7.2]
  def change
    add_column :equipment, :device_type, :string
  end
end
