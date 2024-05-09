class CreateSubscriptions < ActiveRecord::Migration[7.1]
  def change
    create_table :subscriptions do |t|
      t.string :name
      t.string :phone
      t.string :package
      t.string :status
      t.datetime :last_subscribed
      t.datetime :expiry

      t.timestamps
    end
  end
end
