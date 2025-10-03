class AddNameOfCustomerToEquipment < ActiveRecord::Migration[7.2]
  def change
    add_column :equipment, :name_of_customer, :string
  end
end
