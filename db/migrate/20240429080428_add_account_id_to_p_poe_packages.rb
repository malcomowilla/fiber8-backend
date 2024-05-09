class AddAccountIdToPPoePackages < ActiveRecord::Migration[7.1]
  def change
    add_column :p_poe_packages, :account_id, :integer
  end
end
