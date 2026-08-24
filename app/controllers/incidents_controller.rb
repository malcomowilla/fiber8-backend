class IncidentsController < ApplicationController
  set_current_tenant_through_filter
  before_action :set_tenant
  before_action :set_time_zone
  before_action :set_incident, only: [:show, :update, :destroy]

  def set_tenant
    host = request.headers['X-Subdomain']
    @account = Account.find_by(subdomain: host)
    ActsAsTenant.current_tenant = @account
  rescue ActiveRecord::RecordNotFound
    render json: { error: 'Invalid tenant' }, status: :not_found
  end

  def set_time_zone
    Time.zone = GeneralSetting.first&.timezone || Rails.application.config.time_zone
  end

  # GET /api/incidents?month=2026-08&type=outage&status=resolved
  def index
    incidents = Incident.where(account_id: @account.id).order(start_time: :desc)

    if params[:month].present?
      month_start = (Date.parse("#{params[:month]}-01").beginning_of_month rescue nil)
      incidents = incidents.where(start_time: month_start.beginning_of_month..month_start.end_of_month) if month_start
    end

    incidents = incidents.where(incident_type: params[:type]) if params[:type].present? && params[:type] != 'all'
    incidents = incidents.where(status: params[:status]) if params[:status].present? && params[:status] != 'all'

    render json: incidents
  end

  def show
    render json: @incident
  end

  # GET /api/incidents/preview_affected?router_scope=specific&affected_routers[]=R1&active_customers_only=true
  def preview_affected
    scope = affected_voucher_scope(
      router_scope: params[:router_scope] || 'all',
      affected_routers: Array(params[:affected_routers]),
      active_customers_only: ActiveModel::Type::Boolean.new.cast(params[:active_customers_only])
    )

    render json: {
      active_count: scope.where(status: 'active').count,
      expired_count: scope.where(status: 'expired').count,
      total_count: scope.count
    }
  end

  # POST /api/incidents
  def create
    incident = Incident.new(incident_params)
    incident.account_id = @account.id

    if incident.save
      result = incident.compensate && incident.hotspot_affected? ? run_compensation(incident) : nil

      ActivtyLog.create(
        action: 'create', ip: request.remote_ip,
        description: "Recorded incident: #{incident.title}",
        user_agent: request.user_agent,
        user: current_user.username || current_user.email,
        date: Time.current
      )

      render json: incident.as_json.merge(compensation_result: result), status: :created
    else
      render json: { error: incident.errors.full_messages.join(', ') }, status: :unprocessable_entity
    end
  end

  def update
    if @incident.update(incident_params)
      render json: @incident
    else
      render json: { error: @incident.errors.full_messages.join(', ') }, status: :unprocessable_entity
    end
  end

  def destroy
    @incident.destroy
    head :no_content
  end

  # POST /api/incidents/:id/compensate — manually (re)trigger
  def compensate
    incident = Incident.find_by(id: params[:id], account_id: @account.id)
    return render json: { error: 'Incident not found' }, status: :not_found unless incident
    unless incident.hotspot_affected?
      return render json: { error: 'Incident is not marked for hotspot compensation' }, status: :unprocessable_entity
    end

    render json: { compensation_result: run_compensation(incident) }
  end

  private

  def set_incident
    @incident = Incident.find_by(id: params[:id], account_id: @account.id)
    render json: { error: 'Incident not found' }, status: :not_found unless @incident
  end

  def incident_params
    params.require(:incident).permit(
      :title, :incident_type, :status, :start_time, :end_time, :notes,
      :router_scope, :service_type, :compensate, :active_customers_only,
      affected_routers: []
    )
  end

  def affected_voucher_scope(router_scope:, affected_routers:, active_customers_only:)
    scope = HotspotVoucher.where(account_id: @account.id)

    if router_scope == 'specific' && affected_routers.present?
      package_names = HotspotPackage.where(account_id: @account.id, nas_router: affected_routers).pluck(:name)
      scope = scope.where(package: package_names)
    end

    active_customers_only ? scope.where(status: 'active') : scope.where(status: %w[active expired])
  end

  def run_compensation(incident)
    grace_setting = GracePeriodSetting.find_by(account_id: @account.id)
    grace_duration = grace_setting&.duration || 1.day

    scope = affected_voucher_scope(
      router_scope: incident.router_scope,
      affected_routers: incident.affected_routers,
      active_customers_only: incident.active_customers_only
    )

    result = HotspotIncidentCompensationService.new(@account, grace_duration).compensate(scope)

    incident.update(
      compensated_at: Time.current,
      compensated_count: result.compensated_count,
      sms_sent_count: result.sms_sent_count
    )

    { compensated_count: result.compensated_count, sms_sent_count: result.sms_sent_count }
  end
end