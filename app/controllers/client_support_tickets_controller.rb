# app/controllers/client_support_tickets_controller.rb
class ClientSupportTicketsController < ApplicationController
  set_current_tenant_through_filter
  before_action :set_tenant, except: [:system_admin_index, :system_admin_update, :system_admin_stats]

  load_and_authorize_resource except: [:create, :system_admin_index, :system_admin_update, :system_admin_stats]

  def set_tenant
    host = request.headers['X-Subdomain']
    @account = Account.find_by(subdomain: host)
    ActsAsTenant.current_tenant = @account
  rescue ActiveRecord::RecordNotFound
    render json: { error: 'Invalid tenant' }, status: :not_found
  end

  # ── ISP Admin side ────────────────────────────────────────────────
  def index
    @tickets = ClientSupportTicket.where(account_id: @account.id).recent
    render json: @tickets
  end

  def create
    @ticket = ClientSupportTicket.new(ticket_params)
    @ticket.account_id = @account.id
    @ticket.raised_by_name ||= current_user&.username
    @ticket.raised_by_email ||= current_user&.email
    @ticket.raised_by_phone ||= current_user&.phone_number

    if @ticket.save
      notify_system_admins(@ticket)
      render json: @ticket, status: :created
    else
      render json: { errors: @ticket.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def show
    @ticket = ClientSupportTicket.find_by(id: params[:id], account_id: @account.id)
    return render json: { error: 'Not found' }, status: :not_found unless @ticket
    render json: @ticket
  end

  # ── System Admin side (cross-tenant) ──────────────────────────────
  def system_admin_index
    tickets = ActsAsTenant.without_tenant do
      ClientSupportTicket.includes(:account).recent.limit(500)
    end

    render json: tickets.map { |t|
      {
        id: t.id,
        subject: t.subject,
        description: t.description,
        category: t.category,
        priority: t.priority,
        status: t.status,
        raised_by_name: t.raised_by_name,
        raised_by_email: t.raised_by_email,
        raised_by_phone: t.raised_by_phone,
        company_name: t.account&.subdomain,
        created_at: t.created_at,
        resolved_at: t.resolved_at,
        admin_notes: t.admin_notes
      }
    }
  end

  def system_admin_update
    ticket = ActsAsTenant.without_tenant { ClientSupportTicket.find_by(id: params[:id]) }
    return render json: { error: 'Not found' }, status: :not_found unless ticket

    ActsAsTenant.without_tenant do
      if ticket.update(status: params[:status] || ticket.status, admin_notes: params[:admin_notes] || ticket.admin_notes)
        render json: ticket, status: :ok
      else
        render json: { errors: ticket.errors.full_messages }, status: :unprocessable_entity
      end
    end
  end

  def system_admin_stats
    tickets = ActsAsTenant.without_tenant { ClientSupportTicket.all }

    render json: {
      total: tickets.count,
      open: tickets.where(status: 'open').count,
      in_progress: tickets.where(status: 'in_progress').count,
      resolved: tickets.where(status: 'resolved').count,
      closed: tickets.where(status: 'closed').count,
      urgent_open: tickets.where(status: %w[open in_progress], priority: 'urgent').count,
      by_category: tickets.group(:category).count
    }
  end

  private

  def notify_system_admins(ticket)
    company_name = @account.subdomain

    SystemAdmin.find_each do |admin|
      next unless admin.system_admin_phone_number.present?

      message = "New support ticket from #{company_name}: '#{ticket.subject}' " \
                "(#{ticket.priority} priority, #{ticket.category}). Check dashboard for details."

      send_system_admin_sms(admin.system_admin_phone_number, message)
    end

    # Broadcast for a live badge/counter on the system admin dashboard
    SystemAdminTicketChannel.broadcast_to('system_admins', {
      type: 'new_ticket',
      ticket: {
        id: ticket.id,
        subject: ticket.subject,
        priority: ticket.priority,
        category: ticket.category,
        company_name: company_name
      }
    })
  rescue => e
    Rails.logger.error "Failed to notify system admins: #{e.message}"
  end

  def send_system_admin_sms(phone_number, message)
    sender_id = "SMS_TEST"
    uri = URI("https://api.smsleopard.com/v1/sms/send")
    params = {
      username: ENV['SMS_LEOPARD_USERNAME'],
      password: ENV['SMS_LEOPARD_PASSWORD'],
      message: message,
      destination: phone_number,
      source: sender_id
    }
    uri.query = URI.encode_www_form(params)
    Net::HTTP.get_response(uri)
  rescue => e
    Rails.logger.error "SMS send failed: #{e.message}"
  end

  def ticket_params
    params.permit(:subject, :description, :category, :priority,
                   :raised_by_name, :raised_by_email, :raised_by_phone)
  end
end