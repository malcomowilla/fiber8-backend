class AddPasswordResentAtAndPasswordResetTokenToUsers < ActiveRecord::Migration[7.2]
  def change
    add_column :users, :password_reset_sent_at, :datetime
    add_column :users, :password_reset_token, :string
  end
end
