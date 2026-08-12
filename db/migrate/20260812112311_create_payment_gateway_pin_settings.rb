class CreatePaymentGatewayPinSettings < ActiveRecord::Migration[7.2]
   def change
    create_table :payment_gateway_pin_settings do |t|
      t.references :account, null: false, foreign_key: true, index: { unique: true }
      t.string :pin_digest

      t.timestamps
    end
  end
end
