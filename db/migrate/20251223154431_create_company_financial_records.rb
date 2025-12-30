class CreateCompanyFinancialRecords < ActiveRecord::Migration[7.2]
  def change
    create_table :company_financial_records do |t|
      t.string :category
      t.boolean :is_intercompany
      t.string :amount
      t.string :description
      t.string :transaction_type
      t.string :company
      t.datetime :date
      t.string :counterparty
      t.integer :account_id

      t.timestamps
    end
  end
end
