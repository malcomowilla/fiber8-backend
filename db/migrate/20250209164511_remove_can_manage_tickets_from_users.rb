class RemoveCanManageTicketsFromUsers < ActiveRecord::Migration[7.2]
  def change
    remove_column :users, :can_manage_support_tickets, :string
  end
end
