class AddTimePaidPaymentMethodReferenceAmountAndCustomerToHotspotVoucher < ActiveRecord::Migration[7.2]
  def change
    add_column :hotspot_vouchers, :time_paid, :datetime
    add_column :hotspot_vouchers, :payment_method, :string
    add_column :hotspot_vouchers, :reference, :string
    add_column :hotspot_vouchers, :amount, :string
    add_column :hotspot_vouchers, :customer, :string
  end
end
