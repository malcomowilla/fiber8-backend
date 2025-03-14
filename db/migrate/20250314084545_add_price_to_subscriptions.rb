class AddPriceToSubscriptions < ActiveRecord::Migration[7.2]
  def change
    add_column :subscriptions, :price, :string
  end
end
