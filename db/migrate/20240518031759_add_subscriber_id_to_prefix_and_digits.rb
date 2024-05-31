class AddSubscriberIdToPrefixAndDigits < ActiveRecord::Migration[7.1]
  def change
    add_column :prefix_and_digits, :subscriber_id, :integer
  end
end
