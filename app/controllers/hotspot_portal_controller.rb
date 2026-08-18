# app/controllers/hotspot_portal_controller.rb
class HotspotPortalController < ApplicationController
   skip_before_action :verify_authenticity_token, raise: false
  before_action :set_tenant
  before_action :authenticate_portal_token!, except: [:request_otp, :verify_otp]

  TOKEN_TTL = 12.hours

  # POST /api/hotspot/portal/request_otp  { phone_number }
  def request_otp
    phone = normalize_phone(params[:phone_number])
    return render json: { error: 'Phone number required' }, status: :unprocessable_entity if phone.blank?

    unless customer_exists?(phone)
      # Don't reveal existence either way in the error message.
      return render json: { error: 'No hotspot or TV plan history found for this number' }, status: :not_found
    end

    code = HotspotPortalOtp.issue!(@account.id, phone)
    send_otp_sms(phone, code)

    render json: { message: 'Code sent' }, status: :ok
  end

  # POST /api/hotspot/portal/verify_otp  { phone_number, code }
  def verify_otp
    phone = normalize_phone(params[:phone_number])
    unless HotspotPortalOtp.verify!(@account.id, phone, params[:code])
      return render json: { error: 'Invalid or expired code' }, status: :unauthorized
    end


    token = portal_verifier.generate([@account.id, phone, Time.current], expires_in: TOKEN_TTL, purpose: :hotspot_portal)
    render json: { token: token, customer: { phone: phone } }, status: :ok
  end

  # GET /api/hotspot/portal/session
  def session_info
    latest_binding = IpBinding.where(account_id: @account.id, phone: @phone).order(created_at: :desc).first
    tv_plan = latest_binding&.tv_plan_id && TvPlan.find_by(id: latest_binding.tv_plan_id)

    render json: {
      plan: tv_plan&.name,
      expiry: latest_binding&.expiry,
      expired: latest_binding&.expiry.present? && Time.zone.parse(latest_binding.expiry.to_s) < Time.current,
      sessions: IpBinding.where(account_id: @account.id, phone: @phone).count
    }
  end

  # GET /api/hotspot/portal/my_devices
  def my_devices
    settings = HotspotBypassSetting.find_or_create_by(account_id: @account.id)
    devices = IpBinding.where(account_id: @account.id, phone: @phone).order(created_at: :desc)

    render json: devices.map { |d| serialize_device(d, settings) }
  end


   # GET /api/hotspot/portal/payments
  def payments
    revenues = HotspotMpesaRevenue.where(account_id: @account.id, phone_number: @phone)
                                   .or(HotspotMpesaRevenue.where(account_id: @account.id, phone: @phone))
                                   .order(created_at: :desc)
                                   .limit(50)

    render json: revenues.map { |r|
      {
        id: r.id,
        amount: r.amount,
        reference: r.reference,
        payment_method: r.payment_method,
        payment_type: r.respond_to?(:payment_type) ? r.payment_type : 'voucher',
        device_name: r.respond_to?(:device_name) ? r.device_name : nil,
        time_paid: r.time_paid,
        status: r.status
      }
    }
  end



  # POST /api/hotspot/portal/login  { phone_number }
  def login
    phone = normalize_phone(params[:phone_number])
    return render json: { error: 'Phone number required' }, status: :unprocessable_entity if phone.blank?

    unless customer_exists?(phone)
      return render json: { error: 'No hotspot or TV plan history found for this number' }, status: :not_found
    end

    token = portal_verifier.generate([@account.id, phone, Time.current], expires_in: TOKEN_TTL, purpose: :hotspot_portal)
    render json: { token: token, customer: { phone: phone } }, status: :ok
  end





  # PATCH /api/hotspot/portal/devices/:id/replace  { mac_address, ip_address }
  #
  # This is the ONLY device-management mutation a customer can do here — no
  # free "add device". Gated on: binding belongs to this phone, plan not
  # expired, and (settings.tv_plan_replacement_requires_unlock == false OR
  # binding.replacement_allowed == true), and under the replacement cap.
  # 
  
   def replace_device
    binding = IpBinding.find_by(id: params[:id], account_id: @account.id, phone: @phone)
    return render json: { error: 'Device not found' }, status: :not_found unless binding

    settings = HotspotBypassSetting.find_or_create_by(account_id: @account.id)

    if binding.expiry.present? && Time.zone.parse(binding.expiry.to_s) < Time.current
      return render json: { error: 'Your TV plan has expired — renew before replacing a device' }, status: :forbidden
    end

    if settings.tv_plan_replacement_requires_unlock? && !binding.replacement_allowed?
      return render json: { error: 'Ask support to unlock a replacement for this device first' }, status: :forbidden
    end

    if binding.replacement_count >= settings.max_tv_plan_replacements
      return render json: { error: "Replacement limit reached (#{settings.max_tv_plan_replacements})" }, status: :forbidden
    end

    new_mac = params[:mac_address].to_s.strip
    unless new_mac.match?(/\A([0-9A-Fa-f]{2}[:-]){5}[0-9A-Fa-f]{2}\z/)
      return render json: { error: 'Enter a valid MAC address' }, status: :unprocessable_entity
    end

    old_mac = binding.mac

     if binding.update(mac: new_mac, ip: params[:ip_address].presence || binding.ip,
                       replacement_count: binding.replacement_count + 1,
                       replacement_allowed: false) # single-use unlock, admin re-grants if needed
      mikrotik_result = mikrotik_replace_binding(binding, old_mac)
      render json: serialize_device(binding, settings).merge(mikrotik_warning: mikrotik_result[:error])
    else
      render json: binding.errors, status: :unprocessable_entity
    end
  end

  private


    def set_tenant
    host = request.headers['X-Subdomain']
    @account = Account.find_by(subdomain: host)
    return render json: { error: 'Invalid tenant' }, status: :not_found unless @account
    ActsAsTenant.current_tenant = @account
  end

  def authenticate_portal_token!
    header = request.headers['Authorization'].to_s
    token = header.sub(/\ABearer /, '')
    account_id, phone, _issued_at = portal_verifier.verify(token, purpose: :hotspot_portal)
    raise 'account mismatch' unless account_id == @account.id
    @phone = phone
  rescue StandardError
    render json: { error: 'Invalid or expired session' }, status: :unauthorized
  end

  def portal_verifier
    ActiveSupport::MessageVerifier.new(Rails.application.secret_key_base)
  end


  def normalize_phone(raw)
    digits = raw.to_s.gsub(/\D/, '')
    return nil if digits.blank?
    digits = digits.sub(/\A0/, '254')
    digits.start_with?('254') ? digits : "254#{digits}"
  end

  def customer_exists?(phone)
    IpBinding.exists?(account_id: @account.id, phone: phone) ||
      HotspotMpesaRevenue.exists?(account_id: @account.id, phone_number: phone) ||
      HotspotMpesaRevenue.exists?(account_id: @account.id, phone: phone)
  end


  def serialize_device(binding, settings)
    plan_expired = binding.expiry.present? && Time.zone.parse(binding.expiry.to_s) < Time.current
    {
      id: binding.id,
      device_name: binding.name,
      mac_address: binding.mac,
      ip_address: binding.ip,
      device_type: binding.device_type,
      status: binding.status,
      expiry: binding.expiry,
      plan_expired: plan_expired,
      replacement_allowed: binding.replacement_allowed,
      replacements_used: binding.replacement_count,
      max_replacements: settings.max_tv_plan_replacements,
      can_replace: !plan_expired &&
                   (!settings.tv_plan_replacement_requires_unlock? || binding.replacement_allowed?) &&
                   binding.replacement_count < settings.max_tv_plan_replacements
    }
  end


   def mikrotik_replace_binding(binding, old_mac)
    nas = NasRouter.find_by(id: binding.router_id)
    return { error: 'Router not found' } unless nas

    require 'net/ssh'
    old_norm = old_mac.to_s.upcase.gsub('-', ':')
    new_norm = binding.mac.upcase.gsub('-', ':')

    Net::SSH.start(nas.ip_address, nas.username, password: nas.password.to_s,
      verify_host_key: :never, non_interactive: true, timeout: 15) do |ssh|
      ssh.exec!("/ip hotspot ip-binding remove [find mac-address=\"#{old_norm}\"]")
      cmd = "/ip hotspot ip-binding add mac-address=\"#{new_norm}\" type=bypassed server=hotspot1"
      cmd += " address=\"#{binding.ip}\"" if binding.ip.present?
      cmd += " comment=\"#{binding.name}\"" if binding.name.present?
      ssh.exec!(cmd)
    end
    {}
  rescue => e
    { error: e.message }
  end





  def send_otp_sms(phone, code)
    message = "Your Wi-Fi portal login code is #{code}. It expires in 5 minutes."
    provider = @account.sms_provider_setting&.sms_provider
    case provider
    when 'SMS leopard' then send_sms_leopard_raw(phone, message)
    when 'TextSms'     then send_textsms_raw(phone, message)
    when 'Talk Sasa'   then send_talksasa_raw(phone, message)
    else
      Rails.logger.warn "No SMS provider configured for account #{@account.id}, OTP not sent"
    end
  rescue => e
    Rails.logger.error "OTP SMS failed: #{e.message}"
  end
end