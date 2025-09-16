class AddCanReadAndManageInvoiceToUsers < ActiveRecord::Migration[7.2]
  def change
    add_column :users, :can_read_invoice, :boolean
    add_column :users, :can_manage_invoice, :boolean
  end
end
