class CreateSms < ActiveRecord::Migration[7.1]
  def change
    create_table :sms do |t|
      t.string :user
      t.string :message
      t.datetime :date
      t.string :status
      t.string :admin_user
      t.string :system_user
      t.integer :account_id

      t.timestamps
    end
  end
end
