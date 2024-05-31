class RemovePrefixAndMinimumDigitsFromSubscribers < ActiveRecord::Migration[7.1]
  def change
    remove_column :subscribers, :prefix, :string
    remove_column :subscribers, :minimum_digits, :integer
  end
end
