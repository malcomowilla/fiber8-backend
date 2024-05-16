class AddAccountIdToZones < ActiveRecord::Migration[7.1]
  def change
    add_column :zones, :account_id, :integer
  end
end
