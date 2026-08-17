class AddMaxDevicesToTvPlans < ActiveRecord::Migration[7.2]
 def change
    add_column :tv_plans, :max_devices, :integer, default: 1, null: false
  end
end
