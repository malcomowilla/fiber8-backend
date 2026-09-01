class SupportTicket < ApplicationRecord
  auto_increment :sequence_number
  acts_as_tenant(:account)
  belongs_to :subscriber, optional: true
  has_many :ticket_updates, -> { order(created_at: :desc) }, dependent: :destroy
before_create :generate_access_token
  # after_commit :broadcast_ticket_stats, on: [:create, :update, :destroy]

  def generate_access_token
  self.access_token ||= SecureRandom.urlsafe_base64(24)
end

  def broadcast_ticket_stats
    tickets_data = {
      total_tickets: account.support_tickets.count,
      open_tickets: account.support_tickets.where(status: 'Open').count,
      solved_tickets: account.support_tickets.where(status: 'Resolved').count,
      high_priority_tickets: account.support_tickets.where(priority: 'Urgent').count,
      timestamp: Time.current
    }

    TicketsChannel.broadcast_to(account, tickets_data)
  end
end


