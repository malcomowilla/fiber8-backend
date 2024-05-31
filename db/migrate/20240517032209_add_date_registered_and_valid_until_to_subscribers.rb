class AddDateRegisteredAndValidUntilToSubscribers < ActiveRecord::Migration[7.1]
  def change
    add_column :subscribers, :date_registered, :datetime
    add_column :subscribers, :valid_until, :datetime
  end
end
