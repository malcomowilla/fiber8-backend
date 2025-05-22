class AddAccountIdToClientLead < ActiveRecord::Migration[7.2]
  def change
    add_column :client_leads, :account_id, :integer
  end
end
