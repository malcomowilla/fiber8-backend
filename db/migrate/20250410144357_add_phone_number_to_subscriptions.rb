class AddPhoneNumberToSubscriptions < ActiveRecord::Migration[7.2]
  def change
    add_column :subscriptions, :phone_number, :string
  end
end
