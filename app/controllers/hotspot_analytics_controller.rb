class HotspotAnalyticsController < ApplicationController
  set_current_tenant_through_filter
  before_action :set_tenant
  before_action :set_time_zone

  RANGES = [7, 30, 90].freeze
  BUCKET_LABELS = %w[<5m 5-30m 30m-1h 1-3h 3-12h 12h+].freeze

  def set_tenant
    host = request.headers['X-Subdomain']
    @account = Account.find_by!(subdomain: host)
    ActsAsTenant.current_tenant = @account
  rescue ActiveRecord::RecordNotFound
    render json: { error: 'Invalid tenant' }, status: :not_found
  end

  def set_time_zone
    Time.zone = GeneralSetting.first&.timezone || Rails.application.config.time_zone
  end

  # GET /api/hotspot_analytics?days=7|30|90&refresh=1
  def show
    return render json: { error: 'Unauthorized' }, status: :unauthorized unless current_user

    days = params[:days].to_i
    days = 7 unless RANGES.include?(days)

    key = "hotspot_analytics_#{@account.id}_#{days}"
    Rails.cache.delete(key) if params[:refresh].present?

    data = Rails.cache.fetch(key, expires_in: 60.seconds) { build(days) }
    render json: data
  rescue => e
    Rails.logger.error "HotspotAnalytics failed: #{e.class} #{e.message}\n#{e.backtrace.first(5).join("\n")}"
    render json: { error: "Failed to load analytics: #{e.message}" }, status: :unprocessable_entity
  end

  private

  def bucket_index(seconds)
    s = seconds.to_i
    return 0 if s < 300
    return 1 if s < 1800
    return 2 if s < 3600
    return 3 if s < 10_800
    return 4 if s < 43_200
    5
  end

  def build(days)
    since = (days - 1).days.ago.beginning_of_day
    routers = NasRouter.all.to_a
    router_by_name = routers.index_by(&:name)

    packages = HotspotPackage.all.to_a
    router_of_package = packages.each_with_object({}) { |p, h| h[p.name] = p.nas_router }

    # Every voucher of this tenant (for online filtering) and those used in range.
    all_vouchers = HotspotVoucher.where(account_id: @account.id).select(:id, :voucher, :package, :mac, :phone, :last_logged_in).to_a
    in_range = all_vouchers.select { |v| v.last_logged_in.present? && v.last_logged_in >= since }

    usage = native_usage(all_vouchers, in_range, router_by_name, router_of_package)

    revenues = HotspotMpesaRevenue
                 .where(status: 'Completed')
                 .where("hotspot_mpesa_revenues.created_at >= ?", since)

    vouchers_used = revenues.count
    vouchers_revenue = revenues.sum(:amount).to_f

    reachable_ips = RouterStatus.where(tenant_id: @account.id, reachable: true).pluck(:ip)
    routers_up = routers.count { |r| reachable_ips.include?(r.ip_address) }

    # ── Usage over time ──
    day_list = (0...days).map { |i| since.to_date + i }
    vouchers_by_day = revenues.group(Arel.sql("DATE(hotspot_mpesa_revenues.created_at)")).count
    usage_over_time = day_list.map do |d|
      { date: d.iso8601, bytes: usage[:bytes_by_day][d].to_i, vouchers: vouchers_by_day[d].to_i }
    end

    # ── Plan performance ──
    plan_rows = revenues.joins(:hotspot_voucher)
                        .group("hotspot_vouchers.package")
                        .pluck(
                          Arel.sql("hotspot_vouchers.package"),
                          Arel.sql("COUNT(*)"),
                          Arel.sql("SUM(hotspot_mpesa_revenues.amount)")
                        )

    usage_by_pkg = Hash.new { |h, k| h[k] = { bytes: 0, seconds: 0, users: 0 } }
    in_range.each do |v|
      c = usage[:counters][v.voucher]
      next unless c
      usage_by_pkg[v.package][:bytes] += c[:bytes]
      usage_by_pkg[v.package][:seconds] += c[:secs]
      usage_by_pkg[v.package][:users] += 1
    end

    plan_performance = plan_rows.map do |pkg, count, amount|
      u = usage_by_pkg[pkg]
      {
        package: pkg,
        vouchers: count.to_i,
        revenue: amount.to_f,
        avg_bytes: u[:users].positive? ? (u[:bytes] / u[:users]) : 0,
        avg_seconds: u[:users].positive? ? (u[:seconds] / u[:users]) : 0
      }
    end.sort_by { |p| -p[:revenue] }

    # ── Top routers (via package.nas_router) ──
    top_routers = routers.map do |r|
      router_plans = plan_rows.select { |pkg, _, _| router_of_package[pkg] == r.name }
      {
        name: r.name,
        bytes: usage[:bytes_by_router][r.name].to_i,
        vouchers: router_plans.sum { |_, c, _| c.to_i },
        online: usage[:online_by_router][r.name].to_i,
        revenue: router_plans.sum { |_, _, a| a.to_f }
      }
    end.sort_by { |r| -r[:bytes] }.first(5)

    # ── Heatmap (rows Mon..Sun) ──
    heatmap = Array.new(7) { Array.new(24, 0) }
    usage[:heat].each do |(dow, hour), count|
      heatmap[(dow.to_i + 6) % 7][hour.to_i] += count
    end
    busiest_hours = (0..23).map { |h| heatmap.sum { |row| row[h] } }

    session_length = BUCKET_LABELS.each_with_index.map do |label, i|
      { label: label, count: usage[:bucket_counts][i].to_i }
    end

    # ── Heaviest devices ──
    amount_by_voucher = revenues.group(:voucher).sum(:amount)
    heaviest_devices = usage[:devices_list].map do |mac, bytes, secs, usernames|
      {
        mac: mac,
        bytes: bytes.to_i,
        seconds: secs.to_i,
        vouchers: usernames.size,
        spent: usernames.sum { |u| amount_by_voucher[u].to_f }
      }
    end

    # ── Top spending accounts (lifetime) ──
    top_spenders = HotspotMpesaRevenue
      .where(status: 'Completed')
      .joins(:hotspot_voucher)
      .where.not(hotspot_vouchers: { phone: [nil, ''] })
      .group("hotspot_vouchers.phone")
      .order(Arel.sql("SUM(hotspot_mpesa_revenues.amount) DESC"))
      .limit(10)
      .pluck(
        Arel.sql("hotspot_vouchers.phone"),
        Arel.sql("SUM(hotspot_mpesa_revenues.amount)"),
        Arel.sql("COUNT(*)")
      ).map { |phone, spent, count| { phone: phone, spent: spent.to_f, purchases: count.to_i } }

    sessions = usage[:counters].size

    {
      days: days,
      routers_unreachable: usage[:failed_routers],
      generated_at: Time.current.iso8601,
      kpis: {
        data_bytes: usage[:data_bytes],
        devices: usage[:devices],
        time_seconds: usage[:time_seconds],
        sessions: sessions,
        vouchers_used: vouchers_used,
        vouchers_revenue: vouchers_revenue,
        online_now: usage[:online_now],
        avg_session_seconds: sessions.positive? ? (usage[:time_seconds] / sessions) : 0,
        routers_up: routers_up,
        routers_total: routers.size
      },
      usage_over_time: usage_over_time,
      top_routers: top_routers,
      heatmap: heatmap,
      busiest_hours: busiest_hours,
      session_length: session_length,
      plan_performance: plan_performance,
      heaviest_devices: heaviest_devices,
      top_spenders: top_spenders
    }
  end

  # MikroTik keeps lifetime counters per hotspot user (bytes-in/out, uptime),
  # not per-day history. So a voucher counts in the range when its
  # last_logged_in is inside it, and each such voucher is one "session".
  def native_usage(all_vouchers, in_range, router_by_name, router_of_package)
    voucher_names = all_vouchers.map(&:voucher).to_set
    range_by_name = in_range.index_by(&:voucher)

    # which router each voucher lives on = its package's nas_router
    wanted_routers = router_of_package.values.compact.uniq

    counters = {}                       # voucher => { bytes:, secs: }
    bytes_by_router = Hash.new(0)
    online_by_router = Hash.new(0)
    online_users = Set.new
    failed = []

    wanted_routers.each do |router_name|
      nas = router_by_name[router_name]
      next unless nas

      fetched = fetch_router(nas)
      if fetched[:failed]
        failed << nas.name
        next
      end

      active = fetched[:active].select { |a| voucher_names.include?(a['user']) }
      active_by_user = active.index_by { |a| a['user'] }

      active.each { |a| online_users << a['user'] }
      online_by_router[nas.name] += active.size

      fetched[:users].each do |u|
        name = u['name']
        v = range_by_name[name]
        next unless v
        next unless router_of_package[v.package] == nas.name   # only the voucher's own router

        act = active_by_user[name]
        bytes = [u['bytes-in'].to_i + u['bytes-out'].to_i, act ? act['bytes-in'].to_i + act['bytes-out'].to_i : 0].max
        secs  = [parse_uptime(u['uptime']), act ? parse_uptime(act['uptime']) : 0].max
        next unless bytes.positive? || secs.positive?

        counters[name] = { bytes: bytes, secs: secs }
        bytes_by_router[nas.name] += bytes
      end
    end

    bytes_by_day = Hash.new(0)
    heat = Hash.new(0)
    bucket_counts = Hash.new(0)
    by_mac = Hash.new { |h, k| h[k] = { bytes: 0, secs: 0, users: [] } }

    counters.each do |name, c|
      v = range_by_name[name]
      t = v.last_logged_in.in_time_zone
      bytes_by_day[t.to_date] += c[:bytes]
      heat[[t.wday, t.hour]] += 1
      bucket_counts[bucket_index(c[:secs])] += 1

      mac = v.mac.to_s
      next if mac.blank?
      by_mac[mac.upcase][:bytes] += c[:bytes]
      by_mac[mac.upcase][:secs] += c[:secs]
      by_mac[mac.upcase][:users] << name
    end

    devices_list = by_mac.sort_by { |_, m| -m[:bytes] }.first(10).map do |mac, m|
      [mac, m[:bytes], m[:secs], m[:users]]
    end

    {
      counters: counters,
      data_bytes: counters.values.sum { |c| c[:bytes] },
      time_seconds: counters.values.sum { |c| c[:secs] },
      devices: by_mac.size,
      online_now: online_users.size,
      bytes_by_day: bytes_by_day,
      bytes_by_router: bytes_by_router,
      online_by_router: online_by_router,
      heat: heat,
      bucket_counts: bucket_counts,
      devices_list: devices_list,
      failed_routers: failed
    }
  end

  def fetch_router(nas)
    client = RouterosApiClient.new(nas.ip_address, nas.username.to_s, nas.password.to_s, timeout: 8)
    client.connect

    users = client.talk(['/ip/hotspot/user/print', '=.proplist=name,uptime,bytes-in,bytes-out'])
                  .select { |s| s.first == '!re' }.map { |s| sentence_to_hash(s) }
    active = client.talk(['/ip/hotspot/active/print', '=.proplist=user,uptime,bytes-in,bytes-out'])
                   .select { |s| s.first == '!re' }.map { |s| sentence_to_hash(s) }

    { users: users, active: active, failed: false }
  rescue => e
    Rails.logger.error "HotspotAnalytics: router #{nas.ip_address} failed: #{e.class} #{e.message}"
    { users: [], active: [], failed: true }
  ensure
    client&.close
  end

  def sentence_to_hash(sentence)
    sentence.each_with_object({}) do |word, hash|
      next unless word.start_with?('=')
      key, value = word[1..].split('=', 2)
      hash[key] = value
    end
  end

  # RouterOS uptime like "1w2d3h4m5s"
  def parse_uptime(str)
    return 0 if str.blank?
    units = { 'w' => 604_800, 'd' => 86_400, 'h' => 3600, 'm' => 60, 's' => 1 }
    total = 0
    str.to_s.scan(/(\d+)([wdhms])/) { |n, u| total += n.to_i * units[u] }
    total
  end
end