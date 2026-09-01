class AddAccountIdToTicketUpdate < ActiveRecord::Migration[7.2]
  def change
    add_column :ticket_updates, :account_id, :integer
  end
end
