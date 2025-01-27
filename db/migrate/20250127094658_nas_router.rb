class NasRouter < ActiveRecord::Migration[7.1]
  def change
    drop_table :nas_routers
  end
end
