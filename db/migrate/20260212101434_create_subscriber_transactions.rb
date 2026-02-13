class CreateSubscriberTransactions < ActiveRecord::Migration[7.2]
  def change
    create_table :subscriber_transactions do |t|
      t.string :type
      t.string :credit
      t.string :debit
      t.string :date
      t.string :title
      t.string :description
      t.integer :account_id

      t.timestamps
    end
  end
end
