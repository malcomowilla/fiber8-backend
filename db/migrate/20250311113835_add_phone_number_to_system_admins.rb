class AddPhoneNumberToSystemAdmins < ActiveRecord::Migration[7.2]
  def change
    add_column :system_admins, :phone_number, :string
  end
end
