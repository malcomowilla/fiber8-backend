class NasRoutersController < ApplicationController
  rescue_from ActiveRecord::RecordNotFound, with: :router_not_found_response
  rescue_from RouterosApiClient::ApiError do |e|
    render json: { error: e.message }, status: :bad_gateway
  end

  # The two router-command actions are authorized as :update inside the action
  load_and_authorize_resource except: %i[change_router_password reboot]

  set_current_tenant_through_filter
  before_action :set_tenant
  before_action :update_last_activity, except: [:router_ping_response]
  before_action :set_time_zone
  before_action :find_nas_router, only: %i[update delete remote_winbox_session stop_winbox_session
                                           reachability_stats change_router_password reboot]

  def set_time_zone
    Time.zone = GeneralSetting.first&.timezone || Rails.application.config.time_zone
  end

  def update_last_activity
    current_user&.update!(last_activity_active: Time.current)
  end

  def router_ping_response
    @tenant = ActsAsTenant.current_tenant
    router_status = RouterStatus.where(tenant_id: @tenant.id)

    if router_status
      render json: router_status, status: :ok
    else
      render json: { error: "No router status found for tenant #{@tenant.id}" }, status: :not_found
    end
  end

  def set_tenant
    host = request.headers['X-Subdomain']
    @account = Account.find_by!(subdomain: host)
    ActsAsTenant.current_tenant = @account
    EmailConfiguration.configure(@account, ENV['SYSTEM_ADMIN_EMAIL'])
  rescue ActiveRecord::RecordNotFound
    render json: { error: 'Invalid tenant' }, status: :not_found
  end

  def update
    @nas_router.update(nas_router_params)
    log_activity('update', "Updated nas router #{@nas_router.name}")

    render json: safe_router_json(@nas_router)
  end

  # GET /nas_routers or /nas_routers.json
  def index
    @nas_routers = NasRouter.all
    render json: @nas_routers.map { |r| safe_router_json(r) }
  end

  def delete
    if @nas_router.winbox_relay_port
      WinboxRelayService.close(@nas_router, @nas_router.winbox_relay_port)
    end

    @nas_router.destroy
    RouterStatus.where(account_id: @nas_router.account_id).delete_all

    log_activity('delete', "Deleted nas router #{@nas_router.name}")
    head :no_content
  end

  # POST /nas_routers or /nas_routers.json
  def create
    @nas_router = NasRouter.create(nas_router_params)

    if @nas_router
      log_activity('create', "Created nas router #{@nas_router.name}")
      render json: safe_router_json(@nas_router), status: :created
    else
      render json: { error: 'Error Processing the request' }, status: :unprocessable_entity
    end
  end

  def remote_winbox_session
    port = WinboxRelayService.open(@nas_router)

    render json: {
      host: winbox_relay_host,
      port: port,
      expires_at: @nas_router.reload.winbox_relay_expires_at.iso8601
    }
  rescue WinboxRelayService::RelayError => e
    render json: { error: e.message }, status: :conflict
  end

  def stop_winbox_session
    if @nas_router.winbox_relay_port
      WinboxRelayService.close(@nas_router, @nas_router.winbox_relay_port)
    end
    head :no_content
  end

  # POST /api/nas_routers/:id/change_router_password
  # params: username, password, password_confirmation
  # Sets the password for a user ON the router. If that user is the login the
  # platform itself uses for this router, the saved credentials are updated too.
  def change_router_password
    authorize! :update, @nas_router

    username     = params[:username].to_s.strip
    password     = params[:password].to_s
    confirmation = params[:password_confirmation].to_s

    return render_unprocessable('Username is required') if username.blank?
    return render_unprocessable('Password must be at least 8 characters') if password.length < 8
    return render_unprocessable('Passwords do not match') unless password == confirmation

    platform_login = username == @nas_router.username
    old_password   = @nas_router.password
    user_found     = true

    RouterosApiClient.open(@nas_router.ip_address, @nas_router.username, old_password) do |api|
      user = api.print('/user', ["?name=#{username}"]).first
      if user
        api.talk(['/user/set', "=.id=#{user['.id']}", "=password=#{password}"])
      else
        user_found = false
      end
    end

    unless user_found
      return render json: { error: "User '#{username}' does not exist on this router" }, status: :not_found
    end

    if platform_login && !@nas_router.update(password: password)
      revert_router_password(username, password, old_password)
      return render json: { error: 'Could not save the new password, the router was left unchanged' },
                    status: :unprocessable_entity
    end

    log_activity('update', "Changed router login password for '#{username}' on nas router #{@nas_router.name}")
    render json: {
      message: "Password for '#{username}' updated on the router",
      platform_login_updated: platform_login
    }
  end

  # POST /api/nas_routers/:id/reboot
  def reboot
    authorize! :update, @nas_router

    begin
      RouterosApiClient.open(@nas_router.ip_address, @nas_router.username, @nas_router.password) do |api|
        api.talk(['/system/reboot'])
      end
    rescue RouterosApiClient::ApiError => e
      # The router drops the connection as it reboots; that is success.
      raise unless e.message.include?('Connection closed')
    rescue Errno::ECONNRESET, Errno::EPIPE
      nil
    end

    log_activity('update', "Rebooted nas router #{@nas_router.name}")
    render json: { message: 'Router is rebooting' }
  end

  # GET /api/nas_routers/:id/reachability_stats?days=30
  # Aggregates RouterStatusLog transitions into day-of-week / hour-of-day
  # outage counts plus a paired outage timeline (offline -> back online).
  def reachability_stats
    @tenant = ActsAsTenant.current_tenant
    days = (params[:days] || 30).to_i.clamp(1, 365)
    since = days.days.ago

    logs = RouterStatusLog.where(nas_router_id: @nas_router.id, tenant_id: @tenant.id)
                           .where('occurred_at >= ?', since)
                           .order(:occurred_at)

    offline_events = logs.select { |l| !l.reachable }

    day_order = %w[Mon Tue Wed Thu Fri Sat Sun]
    by_day_counts = offline_events.group_by { |l| l.occurred_at.strftime('%a') }
                                   .transform_values(&:count)
    by_day_of_week = day_order.map { |d| { day: d, count: by_day_counts[d] || 0 } }

    by_hour_counts = offline_events.group_by { |l| l.occurred_at.hour }
                                    .transform_values(&:count)
    by_hour = (0..23).map { |h| { hour: h, count: by_hour_counts[h] || 0 } }

    # Pair each "went offline" log with the next "back online" log to get
    # discrete outage windows and durations.
    outages = []
    pending_offline = nil
    logs.each do |log|
      if !log.reachable
        pending_offline = log
      elsif pending_offline
        outages << {
          went_offline_at: pending_offline.occurred_at.iso8601,
          back_online_at: log.occurred_at.iso8601,
          duration_minutes: ((log.occurred_at - pending_offline.occurred_at) / 60).round(1)
        }
        pending_offline = nil
      end
    end

    # Source of truth for "is it down right now" is the live poll
    # (RouterStatus), not the log. The log can lag or, for a router that
    # was already down when this feature shipped, have no matching
    # "went offline" entry at all.
    live_status = RouterStatus.find_by(tenant_id: @tenant.id, ip: @nas_router.ip_address)
    currently_offline = live_status ? !live_status.reachable : false

    # If still offline right now, count the ongoing outage toward
    # downtime/uptime too, instead of only counting closed ones.
    if pending_offline
      downtime_minutes_ongoing = ((Time.current - pending_offline.occurred_at) / 60).round(1)
      outages << {
        went_offline_at: pending_offline.occurred_at.iso8601,
        back_online_at: nil,
        duration_minutes: downtime_minutes_ongoing
      }
    end

    total_period_minutes = days * 24 * 60
    downtime_minutes = outages.sum { |o| o[:duration_minutes] }
    uptime_percent = total_period_minutes.positive? ? (100 - (downtime_minutes / total_period_minutes.to_f * 100)).round(2) : 100.0

    render json: {
      router_id: @nas_router.id,
      router_name: @nas_router.name,
      period_days: days,
      uptime_percent: uptime_percent,
      total_outages: outages.size,
      avg_downtime_minutes: outages.any? ? (downtime_minutes / outages.size).round(1) : 0,
      currently_offline: currently_offline,
      by_day_of_week: by_day_of_week,
      by_hour: by_hour,
      recent_outages: outages.last(15).reverse
    }
  end

  private

  def log_activity(action, description)
    ActivtyLog.create(action: action, ip: request.remote_ip, description: description,
                      user_agent: request.user_agent,
                      user: current_user.username || current_user.email,
                      date: Time.current)
  end

  # Never send router login passwords to the browser.
  def safe_router_json(router)
    router.as_json(except: [:password])
  end

  def render_unprocessable(message)
    render json: { error: message }, status: :unprocessable_entity
  end

  # Best effort: put the old password back on the router if saving the new one failed.
  def revert_router_password(username, new_password, old_password)
    RouterosApiClient.open(@nas_router.ip_address, username, new_password) do |api|
      user = api.print('/user', ["?name=#{username}"]).first
      api.talk(['/user/set', "=.id=#{user['.id']}", "=password=#{old_password}"]) if user
    end
  rescue StandardError => e
    Rails.logger.error "Failed to revert router password for #{@nas_router.id}: #{e.message}"
  end

  def winbox_relay_host
    full_domain = request.headers['X-Domain']
    raise 'Missing X-Domain header for WinBox relay host resolution' if full_domain.blank?

    base_domain = full_domain.split('.').last(3).join('.')
    base_domain == 'owitech.co.ke' ? 'relay.owitech.co.ke' : 'relay.aitechs.co.ke'
  end

  def nas_router_params
    params.require(:nas_router).permit(:name, :ip_address, :username, :password, :location)
  end

  def find_nas_router
    @nas_router = NasRouter.find(params[:id])
  end

  def router_not_found_response
    render json: { error: 'Router Not Found' }, status: :not_found
  end
end