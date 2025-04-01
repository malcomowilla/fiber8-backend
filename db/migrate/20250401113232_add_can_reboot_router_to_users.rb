class AddCanRebootRouterToUsers < ActiveRecord::Migration[7.2]
  def change
    add_column :users, :can_reboot_router, :boolean, default: false
  end

  
end
