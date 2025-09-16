class AddCanReadAndManageEquipmentToUsers < ActiveRecord::Migration[7.2]
  def change
    add_column :users, :can_read_equipment, :boolean
    add_column :users, :can_manage_equipment, :boolean
  end
end
