class AddAccountIdToCompanySettings < ActiveRecord::Migration[7.1]
  def change
    add_column :company_settings, :account_id, :integer
  end
end
