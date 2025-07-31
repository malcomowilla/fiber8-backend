



class TicketsJob
  include Sidekiq::Job
  queue_as :default
  
  def perform

tickets = SupportTicket.all
    tickets.each do |ticket|  
Rails.logger.info "Ticket #{ticket.id} status: #{ticket.status} ticket_number: #{ticket.ticket_number}"
    end



  end
  end