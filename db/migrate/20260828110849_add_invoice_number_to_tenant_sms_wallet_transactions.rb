class AddInvoiceNumberToTenantSmsWalletTransactions < ActiveRecord::Migration[7.2]
 def change
    add_column :tenant_sms_wallet_transactions, :invoice_number, :string
  end
end
