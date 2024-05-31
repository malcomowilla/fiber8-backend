class RemoveUsersIdFromSubscribers < ActiveRecord::Migration[7.1]
  def change
    remove_column :subscribers, :users_id, :string
  end
end
