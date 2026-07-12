class NetworkMapController < ApplicationController
  # GET /network_map.json -> matches api.fetchAll() in NetworkMap.jsx




set_current_tenant_through_filter

before_action :set_tenant




  def set_tenant
    host = request.headers['X-Subdomain']
    @account = Account.find_by(subdomain: host)
    ActsAsTenant.current_tenant = @account
    EmailConfiguration.configure(@account, ENV['SYSTEM_ADMIN_EMAIL'])
    # EmailSystemAdmin.configure(@current_account, current_system_admin)
  Rails.logger.info "Setting tenant for app#{ActsAsTenant.current_tenant}"
  
    # set_current_tenant(@account)
  rescue ActiveRecord::RecordNotFound
    render json: { error: 'Invalid tenant' }, status: :not_found
  
    
  end








  def index
    render json: {
      pops: Pop.all.map(&:as_map_json),
      devices: NetworkDevice.all.map(&:as_map_json),
      connections: NetworkConnection.all.map(&:as_map_json),
    }
  end

  # POST /network_map/sync -> matches api.syncStatus() in NetworkMap.jsx
  def sync
    Pop.where.not(router_id: nil).find_each { |pop| pop.update(status: poll_status(pop.router)) }
    NetworkDevice.where.not(router_id: nil).find_each { |d| d.update(status: poll_status(d.router)) }

    render json: {
      pops: Pop.all.map(&:as_map_json),
      devices: NetworkDevice.all.map(&:as_map_json),
    }
  end

  private

  def poll_status(router)
    return 'unknown' if router.nil?

    # TODO: replace with your actual reachability check, e.g.:
    #   RouterOsClient.new(router).reachable? ? 'active' : 'down'
    router.respond_to?(:online?) && router.online? ? 'active' : 'down'
  end
end