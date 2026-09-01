class TechnicianTicketsController < ApplicationController
  set_current_tenant_through_filter
  before_action :set_tenant
  before_action :set_ticket_by_token

  ALLOWED_STATUSES = ['In Progress', 'Pending', 'Resolved'].freeze

  def show
    render json: {
      ticket_number: @support_ticket.ticket_number,
      customer: @support_ticket.customer,
      issue_description: @support_ticket.issue_description,
      status: @support_ticket.status,
      priority: @support_ticket.priority,
      ticket_category: @support_ticket.ticket_category,
      updates: @support_ticket.ticket_updates.map { |u|
        { status: u.status, remark: u.remark, updated_by: u.updated_by, created_at: u.created_at, source: u.source }
      }
    }
  end

  def update
    unless ALLOWED_STATUSES.include?(update_params[:status])
      return render json: { error: 'Invalid status' }, status: :unprocessable_entity
    end

    ticket_update = @support_ticket.ticket_updates.create!(
      status: update_params[:status],
      remark: update_params[:remark],
      updated_by: update_params[:updated_by].presence || @support_ticket.agent,
      source: 'technician'
    )

    @support_ticket.update!(
      status: update_params[:status],
      technician_updated_at: Time.current,
      date_closed: update_params[:status] == 'Resolved' ? Time.now.strftime('%Y-%m-%d %I:%M:%S %p') : @support_ticket.date_closed
    )

    render json: {
      message: 'Ticket updated',
      status: @support_ticket.status,
      update: { status: ticket_update.status, remark: ticket_update.remark, created_at: ticket_update.created_at }
    }, status: :ok
  end

  private

  def set_tenant
    host = request.headers['X-Subdomain']
    @account = Account.find_by(subdomain: host)
    return render json: { error: 'Invalid tenant' }, status: :not_found unless @account
    ActsAsTenant.current_tenant = @account
  end

  def set_ticket_by_token
    @support_ticket = SupportTicket.find_by(access_token: params[:token])
    render json: { error: 'Ticket not found or link expired' }, status: :not_found unless @support_ticket
  end

  def update_params
    params.require(:ticket_update).permit(:status, :remark, :updated_by)
  end
end