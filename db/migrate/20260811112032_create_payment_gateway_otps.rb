class CreatePaymentGatewayOtps < ActiveRecord::Migration[7.2]
   def change
    create_table :payment_gateway_otps do |t|
      t.references :user, null: false, foreign_key: true
      t.references :account, null: false, foreign_key: true
      t.string :code_digest, null: false
      t.string :channel, null: false # 'sms' or 'email'
      t.integer :attempts, default: 0, null: false
      t.datetime :expires_at, null: false
      t.datetime :consumed_at
      t.string :request_ip

      t.timestamps
    end

    add_index :payment_gateway_otps, [:user_id, :created_at]
    add_index :payment_gateway_otps, [:user_id, :consumed_at]
  end
end
