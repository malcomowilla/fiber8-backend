class AddStatusToTechnician < ActiveRecord::Migration[7.2]
  def change
    add_column :technicians, :status, :string
  end
end
