class AddLocationToNasRouter < ActiveRecord::Migration[7.2]
  def change
    add_column :nas_routers, :location, :string
  end
end
