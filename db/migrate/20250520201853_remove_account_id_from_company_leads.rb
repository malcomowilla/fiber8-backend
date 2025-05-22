class RemoveAccountIdFromCompanyLeads < ActiveRecord::Migration[7.2]
  def change
    remove_column :company_leads, :account_id, :integer
  end
end
