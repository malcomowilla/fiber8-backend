class HotspotSettingsController < ApplicationController
  set_current_tenant_through_filter

  before_action :set_tenant
  before_action :update_last_activity
  load_and_authorize_resource except: %i[get_hotspot_setting allow_get_hotspot_broadcast]
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

  def set_tenant
    host = request.headers['X-Subdomain']
    Rails.logger.info("Setting tenant for host: #{host}")

    @account = Account.find_by(subdomain: host)
    set_current_tenant(@account)

    unless @account
      render json: { error: 'Invalid tenant' }, status: :not_found
    end
  end

  def hotspot_setup
    mac = params[:mac]
    version = params[:v]

    render plain: generate_hotspot_script(mac, version),
           content_type: "text/plain"
  end

  def upload_hotspot_file
    require "tempfile"
    require "net/ftp"

    router_ip   = params[:router_ip]
    username    = params[:router_username]
    password    = params[:router_password]
    subdomain   = request.headers["X-Subdomain"]
    full_domain = request.headers["X-Domain"]

    raise "Missing router details" if router_ip.blank? || username.blank? || password.blank?

    base_domain = full_domain.to_s.split(".").last(3).join(".") if full_domain.present?

    platform_domain =
      if base_domain == "owitech.co.ke"
        "owitech.co.ke"
      else
        "aitechs.co.ke"
      end

    login_html = <<~HTML
      <html>
        <head>
          <script>
            window.location.replace("https://#{subdomain}.#{platform_domain}/hotspot-page?mac=$(mac)&ip=$(ip)&username=$(username)");
          </script>
        </head>
        <body></body>
      </html>
    HTML

    uploaded_to = MikrotikFtpPublisher.new(
      ip:             router_ip,
      username:       username,
      password:       password,
      html_directory: params[:html_directory]
    ).upload_login(login_html)

    render json: {
      status: "ok",
      message: "login.html uploaded successfully",
      path: uploaded_to
    }
  rescue => e
    render json: { status: "error", message: e.message }, status: :unprocessable_entity
  end

  def index
    @account = ActsAsTenant.current_tenant
    @hotspot_settings = @account.hotspot_setting
    render json: {
      phone_number: @hotspot_settings&.phone_number,
      hotspot_name: @hotspot_settings&.hotspot_name,
      hotspot_info: @hotspot_settings&.hotspot_info,
      email: @hotspot_settings&.email,
      voucher_type: @hotspot_settings&.voucher_type,
      voucher_expiration: @hotspot_settings&.voucher_expiration,
      code_length: @hotspot_settings&.code_length,
      voucher_prefix: @hotspot_settings&.voucher_prefix,
      hotspot_banner: @hotspot_settings&.hotspot_banner&.attached? ?
        rails_blob_url(@hotspot_settings.hotspot_banner, host: 'localhost', protocol: 'http', port: 4000) : nil
    }
  end

  def get_hotspot_setting
    @account = ActsAsTenant.current_tenant
    @hotspot_settings = @account.hotspot_setting
    render json: {
      phone_number: @hotspot_settings&.phone_number,
      hotspot_name: @hotspot_settings&.hotspot_name,
      hotspot_info: @hotspot_settings&.hotspot_info,
      email: @hotspot_settings&.email,
      voucher_type: @hotspot_settings&.voucher_type,
      voucher_expiration: @hotspot_settings&.voucher_expiration,
      code_length: @hotspot_settings&.code_length,
      voucher_prefix: @hotspot_settings&.voucher_prefix,
      hotspot_banner: @hotspot_settings&.hotspot_banner&.attached? ?
        rails_blob_url(@hotspot_settings.hotspot_banner, host: 'localhost', protocol: 'http', port: 4000) : nil
    }
  end

  # POST /hotspot_settings or /hotspot_settings.json
  def create
    @hotspot_setting = HotspotSetting.first_or_initialize(
      phone_number: params[:phone_number],
      hotspot_name: params[:hotspot_name],
      hotspot_info: params[:hotspot_info],
      hotspot_banner: params[:hotspot_banner],
      email: params[:email],
      voucher_type: params[:voucher_type],
    )

    if @hotspot_setting.update(
      phone_number: params[:phone_number],
      hotspot_name: params[:hotspot_name],
      hotspot_info: params[:hotspot_info],
      hotspot_banner: params[:hotspot_banner],
      email: params[:email],
      voucher_type: params[:voucher_type],
      voucher_expiration: params[:voucher_expiration],
      code_length: normalized_code_length(params[:code_length]),
      voucher_prefix: normalized_prefix(params[:voucher_prefix]),
    )
      render json: {
        phone_number: @hotspot_setting.phone_number,
        hotspot_name: @hotspot_setting.hotspot_name,
        hotspot_info: @hotspot_setting.hotspot_info,
        email: @hotspot_setting.email,
        voucher_type: @hotspot_setting.voucher_type,
        voucher_expiration: @hotspot_setting.voucher_expiration,
        code_length: @hotspot_setting.code_length,
        voucher_prefix: @hotspot_setting.voucher_prefix,
        hotspot_banner: @hotspot_setting.hotspot_banner.attached? ?
          rails_blob_url(@hotspot_setting.hotspot_banner, host: 'localhost', protocol: 'http', port: 4000) : nil
      },
      status: :created
    else
      render json: @hotspot_setting.errors, status: :unprocessable_entity
    end
  end

  # PATCH/PUT /hotspot_settings/1 or /hotspot_settings/1.json
  def update
    respond_to do |format|
      if @hotspot_setting.update(hotspot_setting_params)
        format.html { redirect_to @hotspot_setting, notice: "Hotspot setting was successfully updated." }
        format.json { render :show, status: :ok, location: @hotspot_setting }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @hotspot_setting.errors, status: :unprocessable_entity }
      end
    end
  end

  # ── Page design ─────────────────────────────────────────────────────

  def save_page_design
    @account = ActsAsTenant.current_tenant
    @hotspot_setting = @account.hotspot_setting

    design = sanitize_page_design(parse_page_design_param(params[:page_design]))

    if params[:design_logo].present?
      @hotspot_setting.design_logo.attach(params[:design_logo])
      design["header"] ||= {}
      design["header"]["logo_url"] = url_for(@hotspot_setting.design_logo)
    end

    if @hotspot_setting.update(page_design: design)
      render json: { status: "ok", page_design: @hotspot_setting.page_design }
    else
      render json: @hotspot_setting.errors, status: :unprocessable_entity
    end
  end

  # Renders compiled HTML WITHOUT publishing.
  #   * { page_design, broadcast }  -> preview of the draft (broadcast is a draft override)
  #   * { router_id }               -> preview of what is currently published on that router
  def preview_page_design
    @account = ActsAsTenant.current_tenant
    platform_domain = PlatformDomainResolvable.resolve(request.headers["X-Domain"])

    router = nil
    broadcast_override = nil

    if params[:router_id].present?
      router = NasRouter.find_by(id: params[:router_id])
      return render json: { status: "error", message: "Router not found" }, status: :not_found unless router

      if router.published_page_design.blank?
        return render plain: no_published_design_html(router), content_type: "text/html"
      end

      design = sanitize_page_design(router.published_page_design.to_h)
    else
      design = sanitize_page_design(parse_page_design_param(params[:page_design]))
      broadcast_override = sanitize_broadcast(params[:broadcast]) if params[:broadcast].present?
    end

    html = HotspotPageBuilder.new(
      @account,
      design_override: design,
      platform_domain: platform_domain,
      router_name: router&.name,
      broadcast_override: broadcast_override
    ).compile(preview: true)

    render plain: html, content_type: "text/html"
  end

  def get_page_design
    @account = ActsAsTenant.current_tenant
    render json: { page_design: @account.hotspot_setting&.page_design || {} }
  end

  # What is currently published on each router (summary only).
  def published_designs
    routers = NasRouter.order(:name)
    render json: routers.map { |r|
      {
        router_id: r.id,
        name: r.name,
        ip_address: r.ip_address,
        published: r.published_page_design.present?,
        published_at: r.page_published_at,
        design: design_summary(r.published_page_design)
      }
    }
  end

  def publish_hotspot_page
    @account = ActsAsTenant.current_tenant

    router = NasRouter.find_by(id: params[:router_id])
    return render json: { status: "error", message: "Router not found" }, status: :not_found unless router

    if router.username.blank?
      return render json: {
        status: "error",
        message: "Router missing FTP credentials"
      }, status: :unprocessable_entity
    end

    platform_domain = PlatformDomainResolvable.resolve(request.headers["X-Domain"])

    html = HotspotPageBuilder.new(
      @account,
      platform_domain: platform_domain,
      router_name: router.name
    ).compile

    uploaded_to = MikrotikFtpPublisher.new(
      ip:             router.ip_address,
      username:       router.username,
      password:       router.password,
      html_directory: router.html_directory
    ).upload_login(html)

    Rails.logger.info("Published hotspot page to #{router.name}: #{uploaded_to}")

    snapshot = @account.hotspot_setting.page_design.presence || { "_default" => true }
    router.update_columns(published_page_design: snapshot, page_published_at: Time.current)

    @account.hotspot_setting.update(page_design_published_at: Time.current)

    render json: {
      status: "ok",
      message: "Published to #{router.name}",
      path: uploaded_to
    }
  rescue Net::FTPError, SocketError, SystemCallError, Timeout::Error => e
    Rails.logger.error("Hotspot publish failed: #{e.class} #{e.message}")
    render json: { status: "error", message: "FTP error: #{e.message}" }, status: :unprocessable_entity
  rescue => e
    Rails.logger.error("Hotspot publish failed: #{e.class} #{e.message}")
    render json: { status: "error", message: e.message }, status: :unprocessable_entity
  end

  # ── Broadcast message ───────────────────────────────────────────────

  # Admin: current broadcast (message is returned even when switched off, so it can be re-enabled)
  def get_broadcast
    setting = ActsAsTenant.current_tenant.hotspot_setting
    render json: broadcast_payload(setting)
  end

  # Admin: save / switch on / switch off
  def save_broadcast
    account = ActsAsTenant.current_tenant
    setting = account.hotspot_setting || account.create_hotspot_setting

    message = params[:message].to_s.strip[0, MAX_BROADCAST_LENGTH]
    level   = BROADCAST_LEVELS.include?(params[:level].to_s) ? params[:level].to_s : "warning"
    enabled = ActiveModel::Type::Boolean.new.cast(params[:enabled]) && message.present?

    if setting.update(
      broadcast_message: message.presence,
      broadcast_level: level,
      broadcast_enabled: enabled,
      broadcast_updated_at: Time.current
    )
      render json: broadcast_payload(setting)
    else
      render json: { error: setting.errors.full_messages.to_sentence }, status: :unprocessable_entity
    end
  end

  # Public (hotspot page, no auth): only returns the message while it is enabled.
  def allow_get_hotspot_broadcast
    payload = broadcast_payload(ActsAsTenant.current_tenant.hotspot_setting)
    payload[:message] = "" unless payload[:enabled]
    response.set_header("Cache-Control", "no-store")
    render json: payload
  end

  private

  MAX_BROADCAST_LENGTH = 280
  BROADCAST_LEVELS = %w[info warning critical].freeze

  def broadcast_payload(setting)
    message = setting&.broadcast_message.to_s
    {
      enabled: !!setting&.broadcast_enabled && message.present?,
      message: message,
      level: setting&.broadcast_level.presence || "warning",
      updated_at: setting&.broadcast_updated_at
    }
  end

  # Draft broadcast sent by the designer's live preview.
  def sanitize_broadcast(raw)
    return nil unless raw.respond_to?(:[])
    level = raw[:level].to_s
    {
      "enabled" => ActiveModel::Type::Boolean.new.cast(raw[:enabled]) || false,
      "message" => raw[:message].to_s.strip[0, MAX_BROADCAST_LENGTH],
      "level"   => BROADCAST_LEVELS.include?(level) ? level : "warning"
    }
  end

  def design_summary(design)
    d = design.is_a?(Hash) ? design : {}
    theme = d["theme"] || {}
    {
      color_scheme: d["color_scheme"],
      primary: theme["primary"],
      secondary: theme["secondary"],
      background: theme["background"],
      font_family: (d["typography"] || {})["font_family"],
      network_name: (d["header"] || {})["network_name"]
    }
  end

  def no_published_design_html(router)
    name = ERB::Util.html_escape(router.name)
    <<~HTML
      <!DOCTYPE html>
      <html><head><meta charset="UTF-8"><meta name="viewport" content="width=device-width, initial-scale=1.0"></head>
      <body style="margin:0;min-height:100vh;display:flex;align-items:center;justify-content:center;font-family:sans-serif;background:#ffffff;color:#111111;text-align:center;padding:24px;">
        <div>
          <p style="font-size:18px;font-weight:700;margin:0 0 8px;">Nothing published yet</p>
          <p style="font-size:14px;margin:0;">No hotspot page has been published to #{name} from the designer.</p>
        </div>
      </body></html>
    HTML
  end

  def set_hotspot_setting
    @hotspot_setting = HotspotSetting.find(params[:id])
  end

  def parse_page_design_param(raw)
    return {} if raw.blank?

    parsed = raw.is_a?(String) ? JSON.parse(raw) : raw.to_unsafe_h
    parsed
  rescue JSON::ParserError
    render json: { status: "error", message: "Invalid page_design payload" }, status: :unprocessable_entity and return {}
  end

  # Whitelist top-level keys but allow free-form nesting underneath.
  ALLOWED_DESIGN_KEYS = %w[color_scheme theme typography layout header footer features].freeze
  ALLOWED_SECTIONS = %w[packages recover voucher mpesa].freeze

  def sanitize_page_design(hash)
    out = hash.slice(*ALLOWED_DESIGN_KEYS)

    if out["layout"].is_a?(Hash) && out["layout"].key?("section_order")
      out["layout"]["section_order"] =
        Array(out["layout"]["section_order"]).map(&:to_s).uniq & ALLOWED_SECTIONS
    end

    out
  end

  def page_design_params
    params.require(:page_design).permit(
      hero: [:title, :subtitle, :logo_url],
      colors: [:primary, :background, :text],
      features: [:show_packages, :show_voucher, :show_mpesa_code],
      footer: [:phone, :email]
    )
  end

  MIN_CODE_LENGTH = 4
  MAX_CODE_LENGTH = 16

  def normalized_code_length(value)
    length = value.to_i
    return MIN_CODE_LENGTH if length <= 0
    length.clamp(MIN_CODE_LENGTH, MAX_CODE_LENGTH)
  end

  MAX_PREFIX_LENGTH = 4

  def normalized_prefix(value)
    value.to_s.strip[0, MAX_PREFIX_LENGTH]
  end

  def generate_hotspot_script(mac, version)
    <<~RSC
    /interface bridge add name=bridge-hotspot comment="Owitech Hotspot"
    /interface/bridge/port add interface=ether5 bridge=bridge-hotspot
    /ip pool
    add name=hotspot-pool ranges=10.3.0.2-10.3.0.254 comment="Hotspot IP Pool Owitech"

    /ip address
    add address=10.3.0.1/24 comment="hotspot network Owitech" interface=bridge-hotspot
    /ip dhcp-server
    add address-pool=hotspot-pool disabled=no interface=bridge-hotspot lease-time=40m name=hotspot-dhcp comment="Hotspot DHCP Owitech"

    /ip dhcp-server network
    add address=10.3.0.0/24 comment="hotspot network Owitech" gateway=10.3.0.1 netmask=255.255.255.0 pool=hotspot-dhcp
    /ip hotspot profile add name=hsprof1 hotspot-address=10.3.0.1

    /ip hotspot add name=hotspot1 interface=bridge-hotspot profile=hsprof1 idle-timeout=00:20:00 keep-alive-timeout=00:20:00 address-pool=hotspot-pool disabled=no comment="Hotspot Owitech"

    /ip dns
    set allow-remote-requests=yes

    /ip firewall nat add chain=srcnat action=masquerade out-interface=bridge-hotspot

    RSC
  end

  def hotspot_setting_params
    params.permit(:phone_number, :hotspot_name,
      :hotspot_info, :hotspot_banner, :account_id, :email,
      :voucher_type, :voucher_expiration, :code_length, :voucher_prefix)
  end
end