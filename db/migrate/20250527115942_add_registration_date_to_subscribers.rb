class AddRegistrationDateToSubscribers < ActiveRecord::Migration[7.2]
  def change
    add_column :subscribers, :registration_date, :datetime
  end
end
