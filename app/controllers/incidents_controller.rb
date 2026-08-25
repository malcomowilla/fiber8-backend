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

  # GET /api/incidents/preview_affected
  def preview_affected
    scope = affected_voucher_scope(
      router_scope: params[:router_scope] || 'all',
      affected_routers: Array(params[:affected_routers]),
      active_customers_only: ActiveModel::Type::Boolean.new.cast(params[:active_customers_only]),
      incident_start: params[:start_time].present? ? (Time.zone.parse(params[:start_time]) rescue Time.current) : Time.current,
      expired_lookback_days: params[:expired_lookback_days].presence&.to_i || 3
    )

    render json: {
      active_count: scope.where(status: 'active').count,
      expired_count: scope.where(status: 'expired').count,
      total_count: scope.count
    }
  end

  # GET /api/incidents/stats?month=2026-08
  def stats
    month_param = params[:month].presence || Time.current.strftime('%Y-%m')
    month_start = (Date.parse("#{month_param}-01").beginning_of_month rescue Date.current.beginning_of_month)
    month_end   = month_start.end_of_month
    year        = month_start.year

    scoped = Incident.where(account_id: @account.id)
    month_incidents = scoped.where(start_time: month_start.beginning_of_day..month_end.end_of_day)

    downtime_hours = downtime_hours_for(month_incidents)
    hours_in_month = ((month_end - month_start).to_f + 1) * 24
    uptime_percent = hours_in_month.positive? ? [[100 - (downtime_hours / hours_in_month * 100), 0].max, 100].min : 100

    threshold_hours = GracePeriodSetting.find_by(account_id: @account.id)&.sla_threshold_hours || 24

    monthly = (1..12).map do |m|
      m_start = Date.new(year, m, 1).beginning_of_month
      m_end = m_start.end_of_month
      m_incidents = scoped.where(start_time: m_start.beginning_of_day..m_end.end_of_day)
      { month: m_start.strftime('%Y-%m'), hours: downtime_hours_for(m_incidents).round(1) }
    end

    type_breakdown = Incident::TYPES.map do |t|
      { incident_type: t, count: month_incidents.where(incident_type: t).count }
    end

    grace_setting = GracePeriodSetting.find_by(account_id: @account.id)
    grace_days_unit = grace_setting ? (grace_setting.duration / 1.day.to_f) : 1.0
    grace_days_granted = (month_incidents.sum(:compensated_count) * grace_days_unit).round(1)

    render json: {
      month_label: month_start.strftime('%B %Y'),
      year: year,
      total_incidents: month_incidents.count,
      uptime_percent: uptime_percent.round(2),
      current_month_downtime_hours: downtime_hours.round(2),
      threshold_hours: threshold_hours,
      active_customers: HotspotVoucher.where(account_id: @account.id, status: 'active').count,
      grace_days_granted: grace_days_granted,
      monthly_downtime_hours: monthly,
      type_breakdown: type_breakdown
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
      :expired_lookback_days,
      affected_routers: []
    )
  end

  def affected_voucher_scope(router_scope:, affected_routers:, active_customers_only:, incident_start:, expired_lookback_days:)
    scope = HotspotVoucher.where(account_id: @account.id)

    if router_scope == 'specific' && affected_routers.present?
      package_names = HotspotPackage.where(account_id: @account.id, nas_router: affected_routers).pluck(:name)
      scope = scope.where(package: package_names)
    end

    return scope.where(status: 'active') if active_customers_only

    cutoff = (incident_start || Time.current) - expired_lookback_days.to_i.days
    scope.where(status: 'active')
         .or(scope.where(status: 'expired').where('expiration >= ?', cutoff))
  end

  def downtime_hours_for(incidents_relation)
    incidents_relation.where(incident_type: %w[outage degradation]).sum do |incident|
      finish = incident.end_time || Time.current
      [((finish - incident.start_time) / 1.hour.to_f), 0].max
    end
  end

  def run_compensation(incident)
    grace_setting = GracePeriodSetting.find_by(account_id: @account.id)
    grace_duration = grace_setting&.duration || 1.day

    scope = affected_voucher_scope(
      router_scope: incident.router_scope,
      affected_routers: incident.affected_routers,
      active_customers_only: incident.active_customers_only,
      incident_start: incident.start_time,
      expired_lookback_days: incident.expired_lookback_days
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