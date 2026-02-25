class AddPhoneNumberToTemporarySession < ActiveRecord::Migration[7.2]
  def change
    add_column :temporary_sessions, :phone_number, :string
  end
end
