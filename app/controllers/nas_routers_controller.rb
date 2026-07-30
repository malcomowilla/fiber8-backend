class NasRoutersController < ApplicationController
  rescue_from ActiveRecord::RecordNotFound, with: :router_not_found_response
  load_and_authorize_resource

  set_current_tenant_through_filter
  before_action :set_tenant
  before_action :update_last_activity, except: [:router_ping_response]
  before_action :set_time_zone
  before_action :find_nas_router, only: [:update, :delete, :remote_winbox_session, :stop_winbox_session]

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
    ActivtyLog.create(action: 'update', ip: request.remote_ip,
      description: "Updated nas router #{@nas_router.name}",
      user_agent: request.user_agent, user: current_user.username || current_user.email,
      date: Time.current)

    render json: @nas_router
  end

  # GET /nas_routers or /nas_routers.json
  def index
    # Tenant checking is disabled for all code in this block
    @nas_routers = NasRouter.all
    render json: @nas_routers
  end

  def delete
    # Close any live WinBox relay before the router row disappears, so we
    # don't leave an orphaned HAProxy listen block + scheduled expiry job
    # pointing at a router that no longer exists.
    if @nas_router.winbox_relay_port
      WinboxRelayService.close(@nas_router, @nas_router.winbox_relay_port)
    end

    @nas_router.destroy
    RouterStatus.where(account_id: @nas_router.account_id).delete_all

    ActivtyLog.create(action: 'delete', ip: request.remote_ip,
      description: "Deleted nas router #{@nas_router.name}",
      user_agent: request.user_agent, user: current_user.username || current_user.email,
      date: Time.current)
    head :no_content
  end

  # POST /nas_routers or /nas_routers.json
  def create
    @nas_router = NasRouter.create(nas_router_params)

    if @nas_router
      ActivtyLog.create(action: 'create', ip: request.remote_ip,
        description: "Created nas router #{@nas_router.name}",
        user_agent: request.user_agent, user: current_user.username || current_user.email,
        date: Time.current)
      render json: @nas_router, status: :created
    else
      render json: { error: 'Error Processing the request' }, status: :unprocessable_entity
    end
  end

  # Opens a temporary WinBox relay to this router via HAProxy.
  # A conf.d file is written on the host, the host-side watcher validates
  # and reloads HAProxy, and the relay auto-closes after 15 minutes via
  # RemoteWinboxExpiryJob (see WinboxRelayService for the actual logic).
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

  # Lets the frontend close the tunnel early (e.g. user closes the WinBox
  # modal) instead of waiting out the full 15 minute TTL.
  def stop_winbox_session
    if @nas_router.winbox_relay_port
      WinboxRelayService.close(@nas_router, @nas_router.winbox_relay_port)
    end
    head :no_content
  end

  private

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
    render json: { error: "Router Not Found" }, status: :not_found
  end
end