class AddStatusToCompanyLeads < ActiveRecord::Migration[7.2]
  def change
     add_column :company_leads, :status, :string, default: 'new', null: false
    add_index :company_leads, :status
      add_column :company_leads, :source, :string, default: 'manual'
    add_index :company_leads, :source
  end
end
