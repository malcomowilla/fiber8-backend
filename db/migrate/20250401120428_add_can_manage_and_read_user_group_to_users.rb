class AddCanManageAndReadUserGroupToUsers < ActiveRecord::Migration[7.2]
  def change
    add_column :users, :can_manage_user_group, :boolean
    add_column :users, :can_read_user_group, :boolean
  end
end
