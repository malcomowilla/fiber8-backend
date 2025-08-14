class AddAccountIdToEquipment < ActiveRecord::Migration[7.2]
  def change
    add_column :equipment, :account_id, :integer
  end
end
