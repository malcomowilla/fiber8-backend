class CreateRouterSettings < ActiveRecord::Migration[7.1]
  def change
    create_table :router_settings do |t|
      t.string :router_name

      t.timestamps
    end
  end
end
