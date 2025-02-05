class AddPhoneNumberToSubscribers < ActiveRecord::Migration[7.1]
  def change
    add_column :subscribers, :phone_number, :string
  end
end
