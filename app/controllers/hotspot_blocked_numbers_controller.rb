class HotspotBlockedNumbersController < ApplicationController
  set_current_tenant_through_filter
  before_action :set_tenant
  before_action :require_login

  def set_tenant
    @account = Account.find_by!(subdomain: request.headers['X-Subdomain'])
    ActsAsTenant.current_tenant = @account
  rescue ActiveRecord::RecordNotFound
    render json: { error: 'Invalid tenant' }, status: :not_found
  end

  def require_login
    render json: { error: 'Please log in' }, status: :unauthorized unless current_user
  end

  # GET /api/hotspot_blocked_numbers
  def index
    records = HotspotBlockedNumber.where(account_id: @account.id).order(created_at: :desc)
    render json: records.map { |r| serialize(r) }
  end

  # POST /api/hotspot_blocked_numbers  { phone_number, reason }
  def create
    normalized = HotspotBlockedNumber.normalize(params[:phone_number])
    unless normalized
      return render json: { error: 'Enter a valid Kenyan phone number, e.g. 0712345678' },
                    status: :unprocessable_entity
    end

    record = HotspotBlockedNumber.new(
      account_id: @account.id,
      phone_number: normalized,
      reason: params[:reason].to_s.strip.presence,
      blocked_by: current_user.username.presence || current_user.email
    )

    if record.save
      ActivtyLog.create(action: 'create', ip: request.remote_ip,
        description: "Blocked #{HotspotBlockedNumber.display(normalized)} from buying hotspot access",
        user_agent: request.user_agent, user: current_user.username || current_user.email,
        date: Time.current)
      render json: serialize(record), status: :created
    else
      message = record.errors.added?(:phone_number, :taken) ? 'That number is already blocked' : record.errors.full_messages.first
      render json: { error: message }, status: :unprocessable_entity
    end
  end

  # DELETE /api/hotspot_blocked_numbers/:id
  def destroy
    record = HotspotBlockedNumber.find_by(id: params[:id], account_id: @account.id)
    return render json: { error: 'Not found' }, status: :not_found unless record

    record.destroy!
    ActivtyLog.create(action: 'delete', ip: request.remote_ip,
      description: "Unblocked #{HotspotBlockedNumber.display(record.phone_number)}",
      user_agent: request.user_agent, user: current_user.username || current_user.email,
      date: Time.current)
    render json: { success: true }
  end

  private

  def serialize(r)
    {
      id: r.id,
      phone_number: HotspotBlockedNumber.display(r.phone_number),
      reason: r.reason,
      blocked_by: r.blocked_by,
      created_at: r.created_at
    }
  end
end