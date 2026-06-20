class MaintenanceController < ApplicationController
 
  set_current_tenant_through_filter

  before_action :set_tenant

  def set_tenant
    host     = request.headers['X-Subdomain']
    @account = Account.find_by!(subdomain: host)
    ActsAsTenant.current_tenant = @account
  rescue ActiveRecord::RecordNotFound
    render json: { error: 'Invalid tenant' }, status: :not_found
  end

  # GET /api/maintenance_status
  # Returns current maintenance state — safe to call without auth
  def status
    # setting = MaintenanceSetting.find_or_initialize_by(account: @account)
    setting = MaintenanceSetting.first

    # Auto-disable if the end time has passed
    if setting.enabled? && setting.until_time.present? && setting.until_time < Time.current
      setting.update(enabled: false)
    end

    render json: {
      enabled:      setting.enabled?,
      until:        setting.until_time&.iso8601,
      message:      setting.message,
      company_name: @account.company_setting&.company_name || @account.subdomain,
    }
  end

  # POST /api/maintenance_mode
  # Body: { enabled: true/false, until: "2025-06-01T14:00", message: "..." }
  # Requires admin auth
  def toggle
    # Only system admins or super-admins should reach this
    # unless current_user&.role.in?(%w[admin superadmin system_admin])
    #   return render json: { error: 'Unauthorized' }, status: :forbidden
    # end

    setting = MaintenanceSetting.find_or_initialize_by(account: @account)

    until_time = params[:until].present? ? Time.zone.parse(params[:until]) : nil

    setting.assign_attributes(
      enabled:    ActiveModel::Type::Boolean.new.cast(params[:enabled]),
      until_time: until_time,
      message:    params[:message].presence,
    )

    if setting.save
      # Broadcast to any connected clients via ActionCable (optional but nice)
      ActionCable.server.broadcast(
        "maintenance_#{@account.subdomain}",
        {
          enabled: setting.enabled?,
          until:   setting.until_time&.iso8601,
          message: setting.message,
        }
      )

      render json: {
        enabled:      setting.enabled?,
        until:        setting.until_time&.iso8601,
        message:      setting.message,
        company_name: @account.company_setting&.company_name || @account.subdomain,
      }
    else
      render json: { error: setting.errors.full_messages.join(', ') }, status: :unprocessable_entity
    end
  end
end