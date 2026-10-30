require 'bigdecimal'
require 'bigdecimal/util'

class RouterInfoController < ApplicationController
  set_current_tenant_through_filter
  before_action :set_tenant
  before_action :find_router, only: %i[router_info get_router_timezone get_router_logs]

  # GET /api/router_info?id=
  def router_info
    with_api do |api|
      resource = api.print('/system/resource').first || {}
      clock    = api.print('/system/clock', proplist: %w[time-zone-name]).first || {}
      pppoe    = safe_count(api, '/ppp/active')
      hotspot  = safe_count(api, '/ip/hotspot/active')

      render json: customize_router_data(resource, clock, pppoe, hotspot)
    end
  end

  # GET /api/router_timezone?id=
  def get_router_timezone
    with_api do |api|
      clock = api.print('/system/clock', proplist: %w[time-zone-name]).first || {}
      render json: { time_zone_name: clock['time-zone-name'] }
    end
  end

  # GET /api/get_router_logs?id=
  def get_router_logs
    with_api(timeout: 20) do |api|
      logs = api.print('/log', proplist: %w[time topics message]).last(500)
      render json: logs.map { |l| { time: l['time'], topics: l['topics'], message: l['message'] } }
    end
  end

  private

  def set_tenant
    @account = Account.find_by(subdomain: request.headers['X-Subdomain'])
    return render json: { error: 'Invalid tenant' }, status: :not_found unless @account

    ActsAsTenant.current_tenant = @account
    EmailConfiguration.configure(@account, ENV['SYSTEM_ADMIN_EMAIL'])
  end

  def find_router
    @router = NasRouter.find_by(id: params[:id])
    render json: { error: 'Router not found' }, status: :not_found unless @router
  end

  def with_api(timeout: 10)
    RouterosApiClient.open(@router.ip_address, @router.username, @router.password, timeout: timeout) do |api|
      yield api
    end
  rescue RouterosApiClient::ApiError => e
    Rails.logger.error "RouterOS API error (router #{@router&.id}): #{e.message}"
    render json: { error: e.message }, status: :bad_gateway
  end

  # A router without the hotspot/ppp package answers with a trap -> treat as 0.
  def safe_count(api, path)
    api.count(path)
  rescue RouterosApiClient::ApiError
    0
  end

  def customize_router_data(data, clock, pppoe, hotspot)
    total_mem = data['total-memory'].to_s.to_d
    free_mem  = data['free-memory'].to_s.to_d
    total_hdd = data['total-hdd-space'].to_s.to_d
    free_hdd  = data['free-hdd-space'].to_s.to_d

    {
      architecture_name: data['architecture-name'],
      board_name: data['board-name'],
      platform: data['platform'],
      cpu: data['cpu'],
      cpu_count: data['cpu-count'],
      cpu_frequency: "#{data['cpu-frequency']} MHz",
      cpu_load: "#{data['cpu-load']}%",
      cpu_load_percent: data['cpu-load'].to_i,
      memory_usage: format_memory_usage(total_mem, free_mem),
      memory_percent: percent_used(total_mem, free_mem),
      disk_usage: format_disk_usage(total_hdd, free_hdd),
      disk_percent: percent_used(total_hdd, free_hdd),
      uptime: data['uptime'],
      version: data['version'],
      build_time: data['build-time'],
      time_zone_name: clock['time-zone-name'],
      active_sessions: pppoe + hotspot,
      pppoe_sessions: pppoe,
      hotspot_sessions: hotspot
    }
  end

  def percent_used(total, free)
    return 0 if total.zero?
    ((total - free) / total * 100).round(1).to_f
  end

  def format_memory_usage(total, free)
    to_mb = ->(v) { v / (1024 * 1024) }
    { total: "#{format_number(to_mb.(total))} MB",
      free: "#{format_number(to_mb.(free))} MB",
      used: "#{format_number(to_mb.(total - free))} MB" }
  end

  def format_disk_usage(total, free)
    to_gb = ->(v) { (v / 1024 / 1024 / 1024).round(2) }
    { total: "#{format_number(to_gb.(total))} GB",
      free: "#{format_number(to_gb.(free))} GB",
      used: "#{format_number(to_gb.(total - free))} GB" }
  end

  def format_number(value)
    value.round(2).to_f.to_s.sub(/\.0+$/, '')
  end
end