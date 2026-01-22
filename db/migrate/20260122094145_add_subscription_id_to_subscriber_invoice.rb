class AddSubscriptionIdToSubscriberInvoice < ActiveRecord::Migration[7.2]
  def change
    add_column :subscriber_invoices, :subscription_id, :integer
  end
end
