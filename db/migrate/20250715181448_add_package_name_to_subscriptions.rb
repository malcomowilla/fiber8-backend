class AddPackageNameToSubscriptions < ActiveRecord::Migration[7.2]
  def change
    add_column :subscriptions, :package_name, :string
  end
end
