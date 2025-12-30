class AddReferenceToCompanyFinancialRecord < ActiveRecord::Migration[7.2]
  def change
    add_column :company_financial_records, :reference, :string
  end
end
