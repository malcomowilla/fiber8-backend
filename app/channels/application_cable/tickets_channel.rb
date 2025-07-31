# class TicketsChannel < ApplicationCable::Channel
#   def subscribed
#     subdomain = params["X-Subdomain"]
#     account = Account.find_by(subdomain: subdomain)

#     if account
#       ActsAsTenant.current_tenant = account
#       stream_for account
#     else
#       reject
#     end
#   end

#   def unsubscribed
#     ActsAsTenant.current_tenant = nil
#   end
# end


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
