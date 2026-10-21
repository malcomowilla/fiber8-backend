class CallCenterController < ApplicationController
  set_current_tenant_through_filter

  before_action :set_account

  def extensions
    render json: ProvisionExtension.list(account: @account)
  end

  def create_extension
    result = ProvisionExtension.call(
      account: @account,
      extension: params[:extension],
      name: params[:name],
      kind: params[:kind]
    )
    return render json: result, status: :unprocessable_entity unless result[:success]

    render json: {
      success: true,
      extension: result[:extension].extension,
      credentials: result[:credentials],
      sip_domain: ENV["ASTERISK_SIP_DOMAIN"]
    }, status: :created
  end

  def update_extension
    result = ProvisionExtension.update(
      account: @account,
      extension: params[:extension],
      name: params[:name],
      kind: params[:kind],
      enabled: params.key?(:enabled) ? ActiveModel::Type::Boolean.new.cast(params[:enabled]) : nil
    )
    render json: result, status: result[:success] ? :ok : :unprocessable_entity
  end

  def destroy_extension
    result = ProvisionExtension.delete(account: @account, extension: params[:extension])
    render json: result, status: result[:success] ? :ok : :unprocessable_entity
  end

  def reset_password
    result = ProvisionExtension.reset_password(account: @account, extension: params[:extension])
    return render json: result, status: :unprocessable_entity unless result[:success]

    render json: result.merge(sip_domain: ENV["ASTERISK_SIP_DOMAIN"])
  end

  # Restrict to admins: returns a SIP password. `extension` in the response is the SIP login (PBX id).
  def softphone
    creds = ProvisionExtension.credentials(account: @account, extension: params[:extension])
    return render json: creds, status: :unprocessable_entity unless creds[:success]

    render json: creds.merge(
      ws_url: ENV.fetch("ASTERISK_WSS_URL"),
      domain: ENV.fetch("ASTERISK_SIP_DOMAIN")
    )
  end

  def live_calls
    by_pbx = @account.sip_extensions.pluck(:pbx_id, :extension).to_h
    calls = AsteriskAmi.new.live_calls(extensions: by_pbx.keys).map do |c|
      c.merge(
        endpoint: by_pbx[c[:endpoint]] || c[:endpoint],
        with: by_pbx[c[:with]] || c[:with]
      )
    end
    render json: { ami_online: true, calls: calls }
  rescue StandardError => e
    Rails.logger.error("[Asterisk] live_calls: #{e.class}: #{e.message}")
    render json: { ami_online: false, calls: [] }
  end

  def stats
    tz = CallCenterSetting.first&.timezone || "Africa/Nairobi"
    now = Time.current.in_time_zone(tz)
    from = case params[:range]
           when "7d"  then (now - 6.days).beginning_of_day
           when "30d" then (now - 29.days).beginning_of_day
           else now.beginning_of_day
           end

    rows = Cdr.where("calldate >= ?", from)
              .pluck(:calldate, :src, :dst, :billsec, :disposition, :dstchannel)
    exts = @account.sip_extensions.pluck(:extension, :name).to_h
    by_pbx = @account.sip_extensions.pluck(:pbx_id, :extension).to_h

    answered = rows.select { |r| r[4] == "ANSWERED" }
    by_hour = Array.new(24, 0)
    rows.each { |r| by_hour[r[0].in_time_zone(tz).hour] += 1 }

    directions = Hash.new(0)
    agents = Hash.new { |h, k| h[k] = { calls: 0, answered: 0 } }
    rows.each do |r|
      dir = direction(r[1], r[2])
      directions[dir] += 1

      agent = dir == "inbound" ? by_pbx[PbxId.from_channel(r[5])] : r[1].to_s
      next unless agent && exts.key?(agent)

      agents[agent][:calls] += 1
      agents[agent][:answered] += 1 if r[4] == "ANSWERED"
    end

    render json: {
      range: params[:range].presence || "today",
      total: rows.size,
      answered: answered.size,
      missed: rows.count { |r| r[4] == "NO ANSWER" },
      busy: rows.count { |r| r[4] == "BUSY" },
      failed: rows.count { |r| r[4] == "FAILED" },
      avg_talk: answered.empty? ? 0 : (answered.sum { |r| r[3].to_i } / answered.size),
      by_hour: by_hour,
      directions: directions,
      top_agents: agents.sort_by { |_, v| -v[:calls] }.first(5).map do |ext, v|
        { extension: ext, name: exts[ext], calls: v[:calls], answered: v[:answered] }
      end
    }
  end

  def calls
    scope = Cdr.order(calldate: :desc)
    scope = scope.where(disposition: params[:disposition]) if params[:disposition].present?
    scope = scope.where("calldate >= ?", Date.parse(params[:from]).beginning_of_day) if params[:from].present?
    scope = scope.where("calldate <= ?", Date.parse(params[:to]).end_of_day) if params[:to].present?
    if params[:q].present?
      like = "%#{Cdr.sanitize_sql_like(params[:q])}%"
      scope = scope.where("src LIKE :q OR dst LIKE :q OR clid LIKE :q", q: like)
    end

    per = 25
    page = [params[:page].to_i, 1].max
    total = scope.count
    has_rec = Cdr.column_names.include?("recordingfile")

    rows = scope.offset((page - 1) * per).limit(per).map do |c|
      {
        id: c.uniqueid,
        calldate: c.calldate,
        src: c.src,
        dst: c.dst,
        clid: c.clid,
        duration: c.duration,
        billsec: c.billsec,
        disposition: c.disposition,
        direction: direction(c.src, c.dst),
        recording: has_rec && c.recordingfile.present?
      }
    end

    render json: { calls: rows, total: total, page: page, per: per }
  rescue ArgumentError
    render json: { error: "Invalid date" }, status: :unprocessable_entity
  end

  def recording
    return head :not_found unless Cdr.column_names.include?("recordingfile")

    cdr = Cdr.find_by(uniqueid: params[:uniqueid])
    return head :not_found unless cdr&.recordingfile.present?

    # Per-tenant folder: <dir>/<padded account id>/<file>
    base = File.expand_path(File.join(ENV.fetch("ASTERISK_RECORDINGS_DIR"), PbxId.suffix(@account.id)))
    path = File.expand_path(cdr.recordingfile, base)
    return head :not_found unless path.start_with?(base + "/") && File.file?(path)

    send_file path, disposition: "inline"
  end

  private

  def set_account
    
    host = request.headers['X-Subdomain']
    @account = Account.find_by(subdomain: host)
     ActsAsTenant.current_tenant = @account
    EmailConfiguration.configure(@account, ENV['SYSTEM_ADMIN_EMAIL'])
    # EmailSystemAdmin.configure(@current_account, current_system_admin)
  
    # set_current_tenant(@account)
  rescue ActiveRecord::RecordNotFound
    render json: { error: 'Account not found' }, status: :not_found
  end

  # Short numbers (3–6 digits) are extensions.
  def direction(src, dst)
    s = src.to_s.match?(/\A\d{3,6}\z/)
    d = dst.to_s.match?(/\A\d{3,6}\z/)
    return "internal" if s && d

    s ? "outbound" : "inbound"
  end
end