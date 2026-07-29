class NasRoutersController < ApplicationController
  rescue_from ActiveRecord::RecordNotFound, with: :router_not_found_response
  load_and_authorize_resource

  set_current_tenant_through_filter
  before_action :set_tenant

  before_action :update_last_activity, except: [:router_ping_response]
  before_action :set_time_zone

  def set_time_zone
    Rails.logger.info "Setting time zone"
    Time.zone = GeneralSetting.first&.timezone || Rails.application.config.time_zone
    Rails.logger.info "Setting time zone #{Time.zone}"
  end

  def update_last_activity
    if current_user
      current_user.update!(last_activity_active: Time.current)
    end
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
    nas_router = find_nas_router
    nas_router.update(nas_router_params)
    ActivtyLog.create(action: 'update', ip: request.remote_ip,
      description: "Updated nas router #{@nas_router.name}",
      user_agent: request.user_agent, user: current_user.username || current_user.email,
      date: Time.current)

    render json: nas_router
  end

  # GET /nas_routers or /nas_routers.json
  def index
    # Tenant checking is disabled for all code in this block
    @nas_routers = NasRouter.all
    render json: @nas_routers
  end

  def delete
    nas_router = find_nas_router

    nas_router.destroy
    RouterStatus.where(account_id: nas_router.account_id).delete_all

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

  # POST /nas_routers/:id/remote_winbox_session
  #
  # No more dynamic iptables DNAT/MASQUERADE rules on the VPS.
  # The static relay (VPS:relay_port -> router_wg_ip:8291) is a one-time,
  # permanent iptables rule set up manually per router (see README notes).
  # This action only tells the MikroTik itself, over the existing WireGuard
  # tunnel via the RouterOS API, to temporarily accept WinBox connections
  # coming from the VPS's WireGuard address. RouterOS expires the
  # address-list entry on its own — no teardown job needed.
  def remote_winbox_session
    nas_router = find_nas_router

    result = WinboxAccessService.new(nas_router).grant_temporary_access

    unless result[:success]
      render json: { error: result[:error] || 'Failed to grant WinBox access, check server logs' },
             status: :unprocessable_entity
      return
    end

    render json: {
      host: winbox_relay_host,
      port: nas_router.winbox_relay_port,
      expires_at: result[:expires_at].iso8601
    }
  end

  private

  def winbox_relay_host
    full_domain = request.headers['X-Domain']
    raise 'Missing X-Domain header for WinBox relay host resolution' if full_domain.blank?

    base_domain = full_domain.split('.').last(3).join('.')
    base_domain == 'owitech.co.ke' ? 'relay.owitech.co.ke' : 'relay.aitechs.co.ke'
  end

  def nas_router_params
    params.require(:nas_router).permit(:name, :ip_address,
      :username, :password, :location)
  end

  # Use callbacks to share common setup or constraints between actions.
  def find_nas_router
    @nas_router = NasRouter.find(params[:id])
  end

  def router_not_found_response
    render json: { error: "Router Not Found" }, status: :not_found
  end
end