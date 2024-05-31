class RemoveUserGroupIdFromSubscribers < ActiveRecord::Migration[7.1]
  def change
    remove_column :subscribers, :user_group, :string
  end
end
