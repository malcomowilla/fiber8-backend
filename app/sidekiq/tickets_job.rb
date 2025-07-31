



class TicketsJob
  include Sidekiq::Job
  queue_as :default
  
  def perform
    Account.find_each do |tenant|
      ActsAsTenant.with_tenant(tenant) do
Rails.logger.info "TicketsJob started"
tickets = SupportTicket.all
    tickets.each do |ticket|  
Rails.logger.info "Ticket #{ticket.id} status: #{ticket.status} ticket_number: #{ticket.ticket_number}"
    end


  end
end
  end

  

  end

