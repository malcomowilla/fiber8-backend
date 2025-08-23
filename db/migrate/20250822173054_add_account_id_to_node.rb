class AddAccountIdToNode < ActiveRecord::Migration[7.2]
  def change
    add_column :nodes, :account_id, :integer
  end
end
