class AddCanManageAndReadFreeRadiusToUsers < ActiveRecord::Migration[7.2]
  def change
    add_column :users, :can_manage_free_radius, :boolean, default: false
    add_column :users, :can_read_free_radius, :boolean, default: false
  end
end
