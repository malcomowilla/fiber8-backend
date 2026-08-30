class AccessPointsController < ApplicationController
  set_current_tenant_through_filter
  before_action :set_tenant
  # before_action :update_last_activity





MIKROTIK_SETUP_INSTRUCTIONS = [
  {
    step: 1,
    title: "Assign Static IP from MikroTik Network",
    description: "Give the access point/router a static IP from your MikroTik hotspot or DHCP network (e.g. 10.5.50.x). Do NOT use default IPs like 192.168.1.1 or 192.168.100.1.",
    command: "# In MikroTik DHCP Server\n# Add Static Lease:\n# IP > DHCP Server > Leases > Add\n# MAC: [device MAC]\n# Address: 10.5.50.x",
    brands: {
      "Huawei" => "Default: 192.168.100.1 — CHANGE THIS to 10.5.50.x",
      "Tenda" => "Default: 192.168.0.1 — CHANGE THIS to 10.5.50.x",
      "TP-Link" => "Default: 192.168.0.1 — CHANGE THIS to 10.5.50.x",
      "ZTE" => "Default: 192.168.1.1 — CHANGE THIS to 10.5.50.x",
    }
  },
  {
    step: 2,
    title: "Check IP Hotspot Hosts",
    description: "After assigning the IP, check if the device appears in MikroTik Hotspot Hosts table.",
    command: "# MikroTik Terminal:\n/ip hotspot host print\n# Look for your device IP",
  },
  {
    step: 3,
    title: "Create IP Binding",
    description: "Double-click the device in Hotspot Hosts → Click 'Make Binding'. This creates a binding in IP > Hotspot > IP Bindings.",
    command: "# MikroTik Terminal:\n/ip hotspot ip-binding add \\\n  address=10.5.50.x \\\n  mac-address=XX:XX:XX:XX:XX:XX \\\n  type=bypassed",
  },
  {
    step: 4,
    title: "Set Binding to Bypassed",
    description: "In IP > Hotspot > IP Bindings, double-click the binding → Set Type to 'Bypassed' → Click Apply → OK.",
    command: "# MikroTik Terminal:\n/ip hotspot ip-binding set [find address=10.5.50.x] type=bypassed",
  },
  {
    step: 5,
    title: "Verify Connectivity",
    description: "Ping the access point from MikroTik terminal to confirm it's reachable.",
    command: "/ping 10.5.50.x count=5",
  }
].freeze





  def set_tenant
    host = request.headers['X-Subdomain']
    @account = Account.find_by(subdomain: host)
    return render json: { error: 'Invalid tenant' }, status: :not_found unless @account
    set_current_tenant(@account)
  end

  # GET /api/access_points
  def index
    access_points = AccessPoint.includes(:nas_router).order(:name)

    render json: {
      access_points: access_points.map { |ap| serialize_ap(ap) },
      summary: {
        total: access_points.count,
        online: access_points.reachable.count,
        offline: access_points.unreachable.count,
        pending_setup: access_points.pending_setup.count,
        fully_setup: access_points.fully_setup.count
      }
    }
  end

  # POST /api/access_points
  def create
    ap = AccessPoint.new(access_point_params)

    # Warn if using default IP
    if ap.using_default_ip?
      return render json: {
        error: ap.default_ip_warning,
        warning: true
      }, status: :unprocessable_entity
    end

    if ap.save
      render json: { access_point: serialize_ap(ap) }, status: :created
    else
      render json: { errors: ap.errors.full_messages }, status: :unprocessable_entity
    end
  end

  # PATCH /api/access_points/:id
  def update
    ap = AccessPoint.find_by(id: params[:id])
    return render json: { error: 'Not found' }, status: :not_found unless ap

    if ap.update(access_point_params)
      render json: { access_point: serialize_ap(ap) }
    else
      render json: { errors: ap.errors.full_messages }, status: :unprocessable_entity
    end
  end

  # DELETE /api/access_points/:id
  def destroy
    ap = AccessPoint.find_by(id: params[:id])
    return render json: { error: 'Not found' }, status: :not_found unless ap
    ap.destroy!
    render json: { message: 'Access point deleted' }
  end

  # PATCH /api/access_points/:id/update_setup_status
  def update_setup_status
    ap = AccessPoint.find_by(id: params[:id])
    return render json: { error: 'Not found' }, status: :not_found unless ap

    if ap.update(setup_status: params[:setup_status])
      render json: { access_point: serialize_ap(ap) }
    else
      render json: { errors: ap.errors.full_messages }, status: :unprocessable_entity
    end
  end

  # GET /api/access_points/analytics
  def analytics
    access_points = AccessPoint.where(account_id: @account.id)

    render json: {
      total: access_points.count,
      online: access_points.reachable.count,
      offline: access_points.unreachable.count,
      offline_list: access_points.unreachable.map { |ap|
        {
          id: ap.id,
          name: ap.name,
          ip: ap.ip,
          location: ap.location,
          last_seen_at: ap.last_seen_at,
          checked_at: ap.checked_at
        }
      },
      avg_latency: access_points.reachable.average(:ping_latency_ms)&.round(2),
      setup_stats: access_points.group(:setup_status).count
    }
  end




def setup_instructions
    render json: { instructions: MIKROTIK_SETUP_INSTRUCTIONS }
  end




  private

  def serialize_ap(ap)
    {
      id: ap.id,
      name: ap.name,
      ip: ap.ip,
      model: ap.model,
      brand: ap.brand,
      location: ap.location,
      mac_address: ap.mac_address,
      reachable: ap.reachable,
      ping_latency_ms: ap.ping_latency_ms,
      checked_at: ap.checked_at,
      last_seen_at: ap.last_seen_at,
      uptime: ap.uptime,
      connected_clients: ap.connected_clients,
      firmware_version: ap.firmware_version,
      snmp_enabled: ap.snmp_enabled,
      snmp_community: ap.snmp_community,
      setup_status: ap.setup_status,
      setup_progress: ap.setup_progress_percent,
      hotspot_binding_done: ap.hotspot_binding_done,
      using_default_ip: ap.using_default_ip?,
      default_ip_warning: ap.default_ip_warning,
      nas_router: ap.nas_router ? { id: ap.nas_router.id, name: ap.nas_router.name } : nil,
      notes: ap.notes
    }
  end

  def access_point_params
    params.permit(
      :name, :ip, :model, :brand, :location, :mac_address,
      :nas_router_id, :snmp_enabled, :snmp_community, :snmp_version,
      :setup_status, :hotspot_binding_done, :notes, :static_ip
    )
  end
end