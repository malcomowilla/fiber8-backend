class AddAccountIdToNas < ActiveRecord::Migration[7.2]
  def change
    add_column :nas, :account_id, :integer
  end
end
