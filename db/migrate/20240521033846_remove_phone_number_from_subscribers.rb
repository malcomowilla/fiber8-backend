class RemovePhoneNumberFromSubscribers < ActiveRecord::Migration[7.1]
  def change
    remove_column :subscribers, :phone_number, :integer
  end
end
