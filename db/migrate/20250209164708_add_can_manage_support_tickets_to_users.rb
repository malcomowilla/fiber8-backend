class AddCanManageSupportTicketsToUsers < ActiveRecord::Migration[7.2]
  def change
    add_column :users, :can_manage_support_tickets, :boolean, default: false
  end
end
