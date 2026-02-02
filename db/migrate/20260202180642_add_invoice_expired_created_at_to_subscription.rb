class AddInvoiceExpiredCreatedAtToSubscription < ActiveRecord::Migration[7.2]
  def change
    add_column :subscriptions, :invoice_expired_created_at, :datetime
  end
end
