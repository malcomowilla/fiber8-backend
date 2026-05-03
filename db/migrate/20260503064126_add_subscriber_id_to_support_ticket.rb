class AddSubscriberIdToSupportTicket < ActiveRecord::Migration[7.2]
  def change
    add_column :support_tickets, :subscriber_id, :integer
  end
end
