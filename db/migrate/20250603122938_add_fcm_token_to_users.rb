class AddFcmTokenToUsers < ActiveRecord::Migration[7.2]
  def change
    add_column :users, :fcm_token, :string
  end
end
