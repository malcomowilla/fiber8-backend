class CreateActivtyLogs < ActiveRecord::Migration[7.2]
  def change
    create_table :activty_logs do |t|
      t.string :action
      t.string :subject
      t.string :description
      t.string :user
      t.datetime :date
      t.integer :account_id

      t.timestamps
    end
  end
end
