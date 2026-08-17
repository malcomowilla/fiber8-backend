# app/controllers/hotspot_portal_controller.rb
class HotspotPortalController < ApplicationController
  set_current_tenant_through_filter
  before_action :set_tenant

  def set_tenant
    host = request.headers['X-Subdomain']
    @account = Account.find_by!(subdomain: host)
    ActsAsTenant.current_tenant = @account
  rescue ActiveRecord::RecordNotFound
    render json: { error: 'Invalid tenant' }, status: :not_found
  end

  # POST /api/hotspot/portal/login  { phone_number: "07..." }
  def login
    phone = normalize_phone(params[:phone_number])
    exists = IpBinding.where(account_id: @account.id, phone: phone).exists? ||
             HotspotMpesaRevenue.where(account_id: @account.id, phone_number: phone).exists?

    return render json: { error: 'No account found for this phone number. Buy a plan first.' }, status: :not_found unless exists

    token = portal_verifier.generate([@account.id, phone], expires_in: 30.days, purpose: :hotspot_portal)
    render json: { token: token, customer: { username: phone } }
  end

  # All other actions require the token
  before_action :authenticate_portal!, except: [:login]

  # GET /api/hotspot/portal/session
  def session
    binding = current_bindings.order(created_at: :desc).first
    render json: {
      plan: binding&.package,
      expiry: binding&.expiry,
      sessions: current_bindings.count
    }
  end

  # GET /api/hotspot/portal/my_devices
  def my_devices
    render json: current_bindings.order(created_at: :desc).map { |d|
      { id: d.id, device_name: d.name, mac_address: d.mac, device_type: d.device_type,
        status: d.status, expiry: d.expiry }
    }
  end

  # POST /api/hotspot/portal/add_device
  def add_device
    settings = HotspotCustomization.find_by(account_id: @account.id)
    limit = settings&.max_customer_bypass_devices || 1
    self_service_allowed = settings&.allow_device_self_service

    active_plan = current_bindings.where(status: 'active').where('expiry IS NULL OR expiry > ?', Time.current).order(created_at: :desc).first
    return render json: { error: 'No active plan on this phone number' }, status: :forbidden unless active_plan

    if current_bindings.count >= limit
      # Only allow if the admin has explicitly flagged this account for a
      # replacement (e.g. their MAC/IP changed and support unlocked one slot)
      return render json: { error: "Device limit reached (#{limit}). Contact support to replace a device." }, status: :forbidden unless active_plan.replacement_allowed?
    end

    binding = IpBinding.create!(
      name: params[:device_name], mac: params[:mac_address], device_type: params[:device_type],
      package: active_plan.package, tv_plan_id: active_plan.tv_plan_id, phone: @portal_phone,
      source: 'tv_plan_purchase', status: 'active', account_id: @account.id,
      router_id: active_plan.router_id, expiry: active_plan.expiry
    )
    push_binding_to_mikrotik(binding)
    active_plan.update(replacement_allowed: false) if active_plan.replacement_allowed?

    render json: { id: binding.id, device_name: binding.name, mac_address: binding.mac,
                   device_type: binding.device_type, status: binding.status }, status: :created
  end

  # DELETE /api/hotspot/portal/devices/:id
  def remove_device
    binding = current_bindings.find(params[:id])
    remove_binding_from_mikrotik(binding)
    binding.destroy!
    head :no_content
  end

  private

  def normalize_phone(p) = p.to_s.strip.sub(/\A0/, '254').sub(/\A\+/, '')

  def portal_verifier
    Rails.application.message_verifier(:hotspot_portal)
  end

  def authenticate_portal!
    token = request.headers['Authorization']&.sub(/\ABearer /, '')
    account_id, phone = portal_verifier.verify(token, purpose: :hotspot_portal)
    return render json: { error: 'Invalid session' }, status: :unauthorized unless account_id == @account.id
    @portal_phone = phone
  rescue ActiveSupport::MessageVerifier::InvalidSignature
    render json: { error: 'Invalid or expired session' }, status: :unauthorized
  end

  def current_bindings
    IpBinding.where(account_id: @account.id, phone: @portal_phone)
  end

  def push_binding_to_mikrotik(binding)
    router = NasRouter.find_by(id: binding.router_id)
    return unless router
    require 'net/ssh'
    mac = binding.mac.upcase.gsub('-', ':')
    cmd = "/ip hotspot ip-binding add mac-address=\"#{mac}\" type=bypassed server=hotspot1"
    cmd += " comment=\"#{binding.name}\"" if binding.name.present?
    Net::SSH.start(router.ip_address, router.username, password: router.password.to_s,
      verify_host_key: :never, non_interactive: true, timeout: 15) { |ssh| ssh.exec!(cmd) }
  rescue => e
    Rails.logger.warn "push_binding_to_mikrotik failed: #{e.message}"
  end

  def remove_binding_from_mikrotik(binding)
    router = NasRouter.find_by(id: binding.router_id)
    return unless router
    require 'net/ssh'
    mac = binding.mac.upcase.gsub('-', ':')
    Net::SSH.start(router.ip_address, router.username, password: router.password.to_s,
      verify_host_key: :never, non_interactive: true, timeout: 15) do |ssh|
      ssh.exec!("/ip hotspot ip-binding remove [find mac-address=\"#{mac}\"]")
    end
  rescue => e
    Rails.logger.warn "remove_binding_from_mikrotik failed: #{e.message}"
  end
end