
class LoadSubscriberTransaction
  include Sidekiq::Job
  queue_as :default


  # :type, :credit, :debit, :date, :title,
  #  :description, :account_id
  def perform
    Account.find_each do |tenant|
      ActsAsTenant.with_tenant(tenant) do

        PpPoeMpesaRevenue.where(account_id: tenant.id).each do |transaction|
          SubscriberTransaction.create!(
            type: 'Deposit',
            credit: transaction.credit,
            debit: transaction.amount,
            date: transaction.time_paid,
            title: transaction.reference,
            description: 'Payment made via M-Pesa',
            account_id: tenant.id
          )

        end
        
  
      end
      end


      
  end






end