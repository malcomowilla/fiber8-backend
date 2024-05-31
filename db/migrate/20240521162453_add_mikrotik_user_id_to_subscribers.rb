class AddMikrotikUserIdToSubscribers < ActiveRecord::Migration[7.1]
  def change
    add_column :subscribers, :mikrotik_user_id, :string
  end
end
