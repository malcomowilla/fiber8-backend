class AddPaymentGatewayToTemporarySessions < ActiveRecord::Migration[7.2]
   def change
    add_column :temporary_sessions, :payment_gateway, :string, default: 'mpesa'
  end
end
