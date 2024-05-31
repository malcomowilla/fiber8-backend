class AddSecondPhoneNumberToSubscribers < ActiveRecord::Migration[7.1]
  def change
    add_column :subscribers, :second_phone_number, :string
  end
end
