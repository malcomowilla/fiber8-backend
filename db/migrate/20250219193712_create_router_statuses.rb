class CreateRouterStatuses < ActiveRecord::Migration[7.2]
  def change
    create_table :router_statuses do |t|
      t.integer :tenant_id
      t.string :ip
      t.boolean :reachable
      t.text :response
      t.datetime :checked_at

      t.timestamps
    end
  end
end
