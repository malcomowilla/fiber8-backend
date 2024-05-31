class AddAccountIdToPrefixAndDigits < ActiveRecord::Migration[7.1]
  def change
    add_column :prefix_and_digits, :account_id, :integer
  end
end
