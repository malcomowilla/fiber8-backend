class AddPasswordToTechnician < ActiveRecord::Migration[7.2]
  def change
    add_column :technicians, :password, :string
  end
end
