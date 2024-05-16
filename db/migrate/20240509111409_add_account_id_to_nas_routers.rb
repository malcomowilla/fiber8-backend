class AddAccountIdToNasRouters < ActiveRecord::Migration[7.1]
  def change
    add_column :nas_routers, :account_id, :integer
  end
end
