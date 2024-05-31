class AddMinimumDigitsToSubscribers < ActiveRecord::Migration[7.1]
  def change
    add_column :subscribers, :minimum_digits, :integer
  end
end
