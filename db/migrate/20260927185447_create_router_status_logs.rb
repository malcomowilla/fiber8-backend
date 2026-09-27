class CreateRouterStatusLogs < ActiveRecord::Migration[7.2]
 def change
    create_table :router_status_logs do |t|
      t.references :nas_router, null: false, foreign_key: true
      t.bigint :tenant_id, null: false
      t.string :ip, null: false
      t.boolean :reachable, null: false
      t.text :response
      t.datetime :occurred_at, null: false
      t.timestamps
    end

    add_index :router_status_logs, [:nas_router_id, :occurred_at]
    add_index :router_status_logs, [:tenant_id, :occurred_at]
  end
end
