



# class TicketsJob
#   include Sidekiq::Job
#   queue_as :default
  
#   def perform
#     Account.find_each do |tenant|
#       ActsAsTenant.with_tenant(tenant) do
# Rails.logger.info "TicketsJob started"
# tickets = SupportTicket.all
#     tickets.each do |ticket|  
# Rails.logger.info "Ticket #{ticket.id} status: #{ticket.status} ticket_number: #{ticket.ticket_number}"
#     end


#   end
# end
#   end



#   end


class TicketsJob
  include Sidekiq::Job
  queue_as :default

  def perform
    Account.find_each do |tenant|
      ActsAsTenant.with_tenant(tenant) do
        Rails.logger.info "TicketsJob started for #{tenant.subdomain}"

        tickets = SupportTicket.all

        tickets_data = tickets.map do |ticket|
          {
            id: ticket.id,
            status: ticket.status,
            ticket_number: ticket.ticket_number
          }
        end

        # Broadcast to the TicketsChannel for this tenant
        TicketsChannel.broadcast_to(
          tenant,
          {
            tickets: tickets_data,
            timestamp: Time.current
          }
        )
      end
    end
  end
end
