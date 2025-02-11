class AddCanReadRouterSettingToUsers < ActiveRecord::Migration[7.2]
  def change
    add_column :users, :can_read_router_setting, :boolean, default: false
  end
end
