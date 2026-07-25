class AddNasRouterToTvPlans < ActiveRecord::Migration[7.2]
 def change
    # Add nas_router_id to tv_plans table
    add_column :tv_plans, :nas_router_id, :bigint unless column_exists?(:tv_plans, :nas_router_id)
    
    # Add foreign key constraint
    add_index :tv_plans, :nas_router_id unless index_exists?(:tv_plans, :nas_router_id)
    
    add_foreign_key :tv_plans, :nas_routers, 
                    column: :nas_router_id, 
                    on_delete: :nullify unless foreign_key_exists?(:tv_plans, :nas_routers)
  end
end
