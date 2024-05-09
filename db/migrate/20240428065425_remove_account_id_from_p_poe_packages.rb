class RemoveAccountIdFromPPoePackages < ActiveRecord::Migration[7.1]
  def change
    remove_column :p_poe_packages, :account_id, :integer
  end
end
