class AddCreditApplicationToReferralsAndInvoices < ActiveRecord::Migration[7.2]
  def change
    add_column :referral_earnings, :applied_to_invoice_id, :bigint
    add_column :referral_earnings, :applied_at, :datetime
    add_index  :referral_earnings, :applied_to_invoice_id

    add_column :invoices, :credit_applied, :decimal, precision: 10, scale: 2, default: 0
  end
end
