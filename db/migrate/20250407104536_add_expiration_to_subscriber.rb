class AddExpirationToSubscriber < ActiveRecord::Migration[7.2]
  def change
    add_column :subscribers, :expiration, :datetime
  end
end
