class AddExpirationDateToSubscriptions < ActiveRecord::Migration[7.2]
  def change
    add_column :subscriptions, :expiration_date, :datetime
  end
end
