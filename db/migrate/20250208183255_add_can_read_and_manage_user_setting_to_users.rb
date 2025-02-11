class AddCanReadAndManageUserSettingToUsers < ActiveRecord::Migration[7.2]
  def change
    add_column :users, :can_manage_user_setting, :boolean, default: false
    add_column :users, :can_read_user_setting, :boolean, default: false
  end

end
