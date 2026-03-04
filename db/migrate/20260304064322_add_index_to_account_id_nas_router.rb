class AddIndexToAccountIdNasRouter < ActiveRecord::Migration[7.2]
  def change
    add_index :nas_routers, :account_id
  end
end
