class AddLockoutColumnsToPaymentGatewayPinSettings < ActiveRecord::Migration[7.2]
  def change
    add_column :payment_gateway_pin_settings, :failed_attempts, :integer, default: 0, null: false
    add_column :payment_gateway_pin_settings, :locked_until, :datetime
  end
end
