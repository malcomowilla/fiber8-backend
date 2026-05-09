# app/controllers/ip_bindings_controller.rb
#
# Manages hotspot IP bindings (MAC bypass) — syncs with MikroTik via SSH.
#
# On create → adds   /ip hotspot ip-binding type=bypassed to MikroTik
# On update → finds old entry by MAC and replaces it
# On destroy → removes the binding from MikroTik then deletes the DB record

class IpBindingsController < ApplicationController
  before_action :set_ip_binding, only: %i[show edit update destroy]

  set_current_tenant_through_filter
  before_action :set_tenant
  before_action :update_last_activity
  before_action :set_time_zone

  # ── tenant / housekeeping ────────────────────────────────────────────────────

  def set_tenant
    host     = request.headers['X-Subdomain']
    @account = Account.find_by!(subdomain: host)
    ActsAsTenant.current_tenant = @account
    EmailConfiguration.configure(@account, ENV['SYSTEM_ADMIN_EMAIL'])
  rescue ActiveRecord::RecordNotFound
    render json: { error: 'Invalid tenant' }, status: :not_found
  end

  def set_time_zone
    Time.zone = GeneralSetting.first&.timezone || Rails.application.config.time_zone
  end

  def update_last_activity
    current_user&.update!(last_activity_active: Time.current)
  end

  # ── CRUD ─────────────────────────────────────────────────────────────────────

  # GET /api/ip_bindings
  def index
    @ip_bindings = IpBinding.all
    render json: @ip_bindings
  end

  # GET /api/ip_bindings/:id
  def show
    render json: @ip_binding
  end

  # POST /api/ip_bindings
  
  def create
  @ip_binding = IpBinding.new(
    router:      params[:router],
    name:        params[:name],
    package:     params[:package],
    mac:         params[:mac],
    ip:          params[:ip],
    expiry:      params[:expiry],
    device_type: params[:device_type],
    router_id:   params[:router_id],
  )

  if @ip_binding.save
    mikrotik_result = mikrotik_add_binding(@ip_binding)

    # ── NEW: create queue if a package is chosen ──────────────────────────
    if @ip_binding.package.present?
      queue_result = mikrotik_add_queue_for_binding(@ip_binding)
      if queue_result[:error]
        Rails.logger.info "MikroTik queue create failed for #{@ip_binding.mac}: #{queue_result[:error]}"
      end
    end
    # ─────────────────────────────────────────────────────────────────────

    if mikrotik_result[:error]
      Rails.logger.info "MikroTik add failed for #{@ip_binding.mac}: #{mikrotik_result[:error]}"
      render json: @ip_binding.as_json.merge(mikrotik_warning: mikrotik_result[:error]), status: :created
    else
      render json: @ip_binding, status: :created
    end
  else
    render json: @ip_binding.errors, status: :unprocessable_entity
  end
end






  # PUT/PATCH /api/ip_bindings/:id
  def update
    old_mac = @ip_binding.mac   # remember before overwrite

    if @ip_binding.update(
      router:      params[:router],
      name:        params[:name],
      package:     params[:package],
      mac:         params[:mac],
      ip:          params[:ip],
      expiry:      params[:expiry],
      device_type: params[:device_type],   # ← fixed
      router_id:   params[:router_id],
    )
      # Remove old binding (by old MAC) then add new one
      mikrotik_result = mikrotik_update_binding(@ip_binding, old_mac)
      if mikrotik_result[:error]
        Rails.logger.warn "MikroTik update failed for #{@ip_binding.mac}: #{mikrotik_result[:error]}"
        render json: @ip_binding.as_json.merge(mikrotik_warning: mikrotik_result[:error])
      else
        render json: @ip_binding
      end
    else
      render json: @ip_binding.errors, status: :unprocessable_entity
    end
  end

  # DELETE /api/ip_bindings/:id
 def destroy
  mikrotik_result = mikrotik_remove_binding(@ip_binding)
  if mikrotik_result[:error]
    Rails.logger.warn "MikroTik remove failed for #{@ip_binding.mac}: #{mikrotik_result[:error]}"
  end

  # ── NEW: remove queue when binding is destroyed ───────────────────────
  if @ip_binding.package.present?
    queue_result = mikrotik_remove_queue_for_binding(@ip_binding)
    if queue_result[:error]
      Rails.logger.warn "MikroTik queue remove failed for #{@ip_binding.mac}: #{queue_result[:error]}"
    end
  end
  # ─────────────────────────────────────────────────────────────────────

  @ip_binding.destroy!
  head :no_content
end

  private

  def set_ip_binding
    @ip_binding = IpBinding.find(params[:id])
  end

  def ip_binding_params
    params.require(:ip_binding).permit(:router, :name, :package, :mac, :ip,
                                       :expiry, :device_type, :account_id, :router_id)
  end




    def mikrotik_add_queue_for_binding(binding)
    router = find_nas_router(binding)
    return { error: "Router not found for binding #{binding.id}" } unless router

    package = HotspotPackage.find_by(name: binding.package)
    return { error: "Package '#{binding.package}' not found" } unless package

    target_ip = binding.ip.presence
    return { error: "No IP address on binding #{binding.id}, cannot create queue" } unless target_ip

    queue_name = binding_queue_name(binding)

    payload = {
      name:               queue_name,
      target:             target_ip,
      "max-limit":        "#{package.upload_limit}M/#{package.download_limit}M",
      # "burst-threshold":  "#{package.burst_threshold_upload}M/#{package.burst_threshold_download}M",
      # "burst-limit":      "#{package.burst_upload_speed}M/#{package.burst_download_speed}M",
      # "burst-time":       "#{package.burst_time}/#{package.burst_time}",
      comment:            "ipbinding_#{binding.id}_#{binding.name}"
    }

    uri = URI("http://#{router.ip_address}/rest/queue/simple/add")
    req = Net::HTTP::Post.new(uri, 'Content-Type' => 'application/json')
    req.basic_auth(router.username, router.password.to_s)
    req.body = payload.to_json

    res = Net::HTTP.start(uri.hostname, uri.port, open_timeout: 10, read_timeout: 10) do |http|
      http.request(req)
    end

    if res.is_a?(Net::HTTPSuccess)
      Rails.logger.info "[IpBindingsController] Queue '#{queue_name}' created for binding #{binding.id}"
      {}
    else
      { error: "MikroTik rejected queue creation: #{res.body}" }
    end
  rescue => e
    { error: e.message }
  end

  def mikrotik_remove_queue_for_binding(binding)
    router = find_nas_router(binding)
    return { error: "Router not found for binding #{binding.id}" } unless router

    queue_name = binding_queue_name(binding)

    # 1. Find the queue's internal .id
    uri = URI("http://#{router.ip_address}/rest/queue/simple/find?name=#{URI.encode_www_form_component(queue_name)}")
    req = Net::HTTP::Get.new(uri)
    req.basic_auth(router.username, router.password.to_s)

    res = Net::HTTP.start(uri.hostname, uri.port, open_timeout: 10, read_timeout: 10) do |http|
      http.request(req)
    end

    unless res.is_a?(Net::HTTPSuccess)
      return { error: "Could not search for queue '#{queue_name}': #{res.body}" }
    end

    ids = JSON.parse(res.body)
    if ids.empty?
      Rails.logger.info "[IpBindingsController] Queue '#{queue_name}' not found on router, skipping removal."
      return {}
    end

    queue_id = ids.first  # MikroTik returns [".id"] strings in find results

    # 2. Remove it
    uri2 = URI("http://#{router.ip_address}/rest/queue/simple/remove")
    req2 = Net::HTTP::Post.new(uri2, 'Content-Type' => 'application/json')
    req2.basic_auth(router.username, router.password.to_s)
    req2.body = { '.id' => queue_id }.to_json

    res2 = Net::HTTP.start(uri2.hostname, uri2.port, open_timeout: 10, read_timeout: 10) do |http|
      http.request(req2)
    end

    if res2.is_a?(Net::HTTPSuccess)
      Rails.logger.info "[IpBindingsController] Queue '#{queue_name}' removed for binding #{binding.id}"
      {}
    else
      { error: "Failed to remove queue '#{queue_name}': #{res2.body}" }
    end
  rescue => e
    { error: e.message }
  end



  def binding_queue_name(binding)
    "binding_#{binding.mac.upcase.gsub(':', '')}"
  end


  
  # ── MikroTik SSH helpers ─────────────────────────────────────────────────────

  # Looks up the NasRouter record for this binding.
  # Tries router_id first, then falls back to matching by name.
  def find_nas_router(binding)
    if binding.router_id.present?
      NasRouter.find_by(id: binding.router_id)
    else
      NasRouter.find_by(name: binding.router)
    end
  end

  # Opens an SSH session to the router and yields the channel.
  # Returns { error: "message" } if anything goes wrong before the block.
  def with_mikrotik_ssh(router)
    require 'net/ssh'

    ip       = router.ip_address
    username = router.username
    password = router.password.to_s

    result = {}

    Net::SSH.start(ip, username,
      password:        password,
      auth_methods:    %w[password keyboard-interactive],
      non_interactive: true,
      timeout:         15,
      verify_host_key: :never,
    ) do |ssh|
      result = yield(ssh)
    end

    result
  rescue Net::SSH::AuthenticationFailed => e
    { error: "SSH auth failed for #{router.ip_address}: #{e.message}" }
  rescue Errno::ECONNREFUSED, Errno::EHOSTUNREACH, Errno::ETIMEDOUT, Net::SSH::ConnectionTimeout => e
    { error: "SSH connection to #{router.ip_address} failed: #{e.message}" }
  rescue => e
    { error: "SSH error: #{e.message}" }
  end

  # Runs a single command and returns its output string.
  def ssh_exec(ssh, command)
    Rails.logger.info "MikroTik SSH >> #{command}"
    output = ssh.exec!(command).to_s.strip
    Rails.logger.info "MikroTik SSH << #{output}" unless output.blank?
    output
  end

  # Finds the MikroTik internal .id for a hotspot ip-binding by MAC address.
  # Returns the .id string (e.g. "*1A") or nil if not found.
  def mikrotik_find_binding_id(ssh, mac)
    # Normalize MAC to MikroTik uppercase colon format
    normalized = mac.upcase.gsub('-', ':')
    output = ssh_exec(ssh, "/ip hotspot ip-binding print terse where mac-address=\"#{normalized}\"")

    # terse line looks like:  0 mac-address=AA:BB:CC:DD:EE:FF ...
    # We need the .id — fetch it via a value-only print
    id_output = ssh_exec(ssh, "/ip hotspot ip-binding get [find mac-address=\"#{normalized}\"] .id")
    id_output.blank? ? nil : id_output
  end

  # Builds the MikroTik add command for a binding record.
  def build_add_command(binding)
    mac        = binding.mac.upcase.gsub('-', ':')
    cmd        = "/ip hotspot ip-binding add mac-address=\"#{mac}\" type=bypassed"
    cmd       += " address=\"#{binding.ip}\""      if binding.ip.present?
    cmd       += " comment=\"#{binding.name}\""    if binding.name.present?
    cmd       += " server=hotspot1"    # apply to all hotspot servers; narrow down if needed
    cmd
  end

  # ── public MikroTik operations ───────────────────────────────────────────────

  def mikrotik_add_binding(binding)
    router = find_nas_router(binding)
    return { error: "Router not found for binding #{binding.id}" } unless router

    with_mikrotik_ssh(router) do |ssh|
      output = ssh_exec(ssh, build_add_command(binding))
      # MikroTik returns empty string on success; any "failure:" prefix = error
      output.downcase.start_with?('failure') ? { error: output } : {}
    end
  end

  def mikrotik_update_binding(binding, old_mac)
    router = find_nas_router(binding)
    return { error: "Router not found for binding #{binding.id}" } unless router

    with_mikrotik_ssh(router) do |ssh|
      # 1. Remove old entry (by old MAC) — ignore error if it doesn't exist
      old_normalized = old_mac.upcase.gsub('-', ':')
      remove_cmd     = "/ip hotspot ip-binding remove [find mac-address=\"#{old_normalized}\"]"
      ssh_exec(ssh, remove_cmd)

      # 2. Add new entry
      output = ssh_exec(ssh, build_add_command(binding))
      output.downcase.start_with?('failure') ? { error: output } : {}
    end
  end

  def mikrotik_remove_binding(binding)
    router = find_nas_router(binding)
    return { error: "Router not found for binding #{binding.id}" } unless router

    with_mikrotik_ssh(router) do |ssh|
      mac        = binding.mac.upcase.gsub('-', ':')
      remove_cmd = "/ip hotspot ip-binding remove [find mac-address=\"#{mac}\"]"
      output     = ssh_exec(ssh, remove_cmd)
      # Returns empty on success; "no such item" is also acceptable (already gone)
      output.downcase.include?('failure') ? { error: output } : {}
    end
  end
end