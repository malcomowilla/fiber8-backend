class AddFirstAndLastNameToTechnician < ActiveRecord::Migration[7.2]
  def change
    add_column :technicians, :first_name, :string
    add_column :technicians, :last_name, :string
  end
end
