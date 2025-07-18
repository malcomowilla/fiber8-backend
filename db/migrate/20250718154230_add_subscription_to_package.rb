class AddSubscriptionToPackage < ActiveRecord::Migration[7.2]
  def change
    add_column :packages, :subscription, :string
  end
end
