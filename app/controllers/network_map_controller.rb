# frozen_string_literal: true

class NetworkMapController < ApplicationController
  # Swap this for whatever your JWT-cookie presence check is actually
  # called elsewhere in the app (per your existing pattern of a presence
  # check replacing `authenticate_user!`).
  before_action :require_login
  set_current_tenant_through_filter

  before_action :set_tenant

  # GET /network_map.json -> api.fetchAll()
  def index
    authorize! :read, Pop
    render json: {
      pops: Pop.all.map(&:as_map_json),
      devices: NetworkDevice.all.map(&:as_map_json),
      connections: NetworkConnection.all.map(&:as_map_json),
    }
  end

  # POST /network_map/sync -> api.syncStatus()
  def sync
    authorize! :manage, Pop
    Pop.where.not(router_id: nil).find_each { |pop| pop.update(status: poll_status(pop.router)) }
    NetworkDevice.where.not(router_id: nil).find_each { |d| d.update(status: poll_status(d.router)) }

    render json: {
      pops: Pop.all.map(&:as_map_json),
      devices: NetworkDevice.all.map(&:as_map_json),
    }
  end

  private

  def set_tenant
    host = request.headers['X-Subdomain']
    @account = Account.find_by(subdomain: host)
    return render json: { error: 'Invalid tenant' }, status: :not_found unless @account

    ActsAsTenant.current_tenant = @account
    # NOTE: the original version of this action also called
    # `EmailConfiguration.configure(@account, ENV['SYSTEM_ADMIN_EMAIL'])`
    # here. That looked like a copy-paste leftover — it doesn't belong on
    # a JSON polling endpoint that fires on every map load/sync. Removed.
    # If it was intentional, tell me and I'll put it back somewhere sane
    # (e.g. a session-start hook instead of every request).
  end

  def poll_status(router)
    return 'unknown' if router.nil?

    # TODO: replace with your actual reachability check, e.g.:
    #   RouterOsClient.new(router).reachable? ? 'active' : 'down'
    router.respond_to?(:online?) && router.online? ? 'active' : 'down'
  end
end