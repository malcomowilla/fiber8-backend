



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

        # Collect ticket stats
        tickets_data = {
          total_tickets: SupportTicket.count,
          open_tickets: SupportTicket.where(status: 'Open').count,
          solved_tickets: SupportTicket.where(status: 'Resolved').count,
          high_priority_tickets: SupportTicket.where(priority: 'Urgent').count
        }

        # Broadcast to the TicketsChannel for this tenant
        TicketsChannel.broadcast_to(
          tenant,
          {
            tickets: tickets_data,
            timestamp: Time.current
          }
        )

        Rails.logger.info "Broadcasted tickets data for #{tenant.subdomain}"
      end
    end
  end
end



