class AddUserIdToPrefixAndDigits < ActiveRecord::Migration[7.1]
  def change
    add_column :prefix_and_digits, :user_id, :integer
  end
end
