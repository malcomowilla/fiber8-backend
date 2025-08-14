class RemoveTypeFromEquipment < ActiveRecord::Migration[7.2]
  def change
    remove_column :equipment, :type, :string
  end
end
