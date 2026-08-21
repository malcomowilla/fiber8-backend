class CreatePaymentGatewaySettings < ActiveRecord::Migration[7.2]
  def change
    create_table :payment_gateway_settings do |t|
      t.references :account, null: false, foreign_key: true
      t.string :use_case, null: false   # 'hotspot' | 'tv_plans'
      t.string :gateway,  null: false   # 'mpesa' | 'tuma' | 'paystack' | 'sasapay'
      t.timestamps
    end
    add_index :payment_gateway_settings, [:account_id, :use_case], unique: true
  end
end
