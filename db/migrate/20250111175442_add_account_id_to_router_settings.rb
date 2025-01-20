class AddAccountIdToRouterSettings < ActiveRecord::Migration[7.1]
  def change
    add_column :router_settings, :account_id, :integer
  end
end
