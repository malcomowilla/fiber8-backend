class CreateIspSubscriptions < ActiveRecord::Migration[7.2]
  def change



    create_table :isp_subscriptions do |t|
      t.integer :account_id
      t.datetime :next_billing_date
      t.string :payment_status
      t.string :currency, default: "KES"
      t.string :plan_name
      t.string :features, default: [], array: true
      t.string :renewal_period,  default: "monthly"
      t.datetime :last_payment_date

      t.timestamps
    end
  end
end
