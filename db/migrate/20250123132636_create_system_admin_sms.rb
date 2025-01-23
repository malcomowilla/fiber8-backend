class CreateSystemAdminSms < ActiveRecord::Migration[7.1]
  def change
    create_table :system_admin_sms do |t|
      t.string :user
      t.string :message
      t.string :status
      t.datetime :date
      t.string :system_user

      t.timestamps
    end
  end
end
