class TenantSmsWallet < ApplicationRecord
  acts_as_tenant(:account)
  belongs_to :account
  has_many :transactions, class_name: 'TenantSmsWalletTransaction'

  def self.for_current_tenant
    find_or_create_by!(account_id: ActsAsTenant.current_tenant.id)
  end

  def self.initiate_purchase!(account_id:, quantity:, amount:)
    wallet = find_or_create_by!(account_id: account_id)
    txn = wallet.transactions.create!(
      account_id: account_id, transaction_type: 'purchase',
      quantity: quantity, amount: amount, status: 'pending'
    )
    [wallet, txn]
  end

  # Completes the pending purchase txn, credits the balance, and generates
  # a paid receipt Invoice — all in one lock, all idempotent against
  # duplicate M-Pesa callbacks.
  def complete_purchase!(txn, paid_amount:)
    with_lock do
      return txn if txn.status == 'completed'

      increment!(:balance, txn.quantity)
      invoice = create_receipt_invoice!(txn, paid_amount)
      txn.update!(status: 'completed', amount: paid_amount, invoice_number: invoice.invoice_number)
    end
    txn
  end

  def debit!(quantity, reference: nil)
    with_lock do
      raise 'Insufficient SMS balance' if balance < quantity
      decrement!(:balance, quantity)
      transactions.create!(
        account_id: account_id, transaction_type: 'send',
        quantity: quantity, reference: reference, status: 'completed'
      )
    end
  end

  private

  # SMS purchases are prepaid via STK at purchase time — there's no
  # "unpaid, due in 5 days" step like the plan-billing invoices. So this
  # is created already status: 'paid', due_date == invoice_date.
  def create_receipt_invoice!(txn, paid_amount)
    tenant = Account.find_by(id: account_id)
    invoice = nil

    ActsAsTenant.with_tenant(tenant) do
      invoice = Invoice.create!(
        invoice_number: self.class.generate_sms_invoice_number,
        plan_name: 'SMS Credits',
        invoice_date: Time.current,
        due_date: Time.current,
        invoice_desciption: {
          summary: 'SMS credits purchase',
          items: [{
            description: "SMS credits (#{txn.quantity})",
            details: 'Prepaid SMS bundle purchased via M-Pesa',
            quantity: txn.quantity,
            unit: 'credits',
            rate: "KES #{(paid_amount / txn.quantity.to_f).round(2)}/credit",
            amount: paid_amount,
            currency: 'KES'
          }]
        }.to_json,
        total: paid_amount,
        amount_paid: paid_amount,
        status: 'paid',
        account_id: account_id,
        last_invoiced_at: Time.current
      )
    end

    invoice
  end

  def self.generate_sms_invoice_number
    loop do
      code = "SMS#{SecureRandom.hex(3).upcase}"
      break code unless Invoice.exists?(invoice_number: code)
    end
  end
end