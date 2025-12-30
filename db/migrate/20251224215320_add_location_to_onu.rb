class AddLocationToOnu < ActiveRecord::Migration[7.2]
  def change
    add_column :onus, :location, :string
  end
end
