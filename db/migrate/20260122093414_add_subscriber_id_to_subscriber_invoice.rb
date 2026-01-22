class AddSubscriberIdToSubscriberInvoice < ActiveRecord::Migration[7.2]
  def change
    add_column :subscriber_invoices, :subscriber_id, :integer
  end
end
