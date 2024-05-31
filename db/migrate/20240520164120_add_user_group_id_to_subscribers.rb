class AddUserGroupIdToSubscribers < ActiveRecord::Migration[7.1]
  def change
    add_column :subscribers, :user_group, :string
  end
end
