class RemoveSubscriberIdFromPrefixAndDigits < ActiveRecord::Migration[7.1]
  def change
    remove_column :prefix_and_digits, :subscriber_id, :integer
  end
end
