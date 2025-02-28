class AddAccountIdToRouterStatuses < ActiveRecord::Migration[7.2]
  def change
    add_column :router_statuses, :account_id, :integer
  end
end
