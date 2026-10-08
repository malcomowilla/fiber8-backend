class PaidNotConnectedController < ApplicationController
  set_current_tenant_through_filter
  before_action :set_tenant
  before_action :set_time_zone

  MIN_AGE_MINUTES = 10          # give them time to still be connecting
  MAX_AUTO_PER_30_DAYS = 2      # more than this = needs a human look
  UNIT_MINUTES = { 'minutes' => 1, 'hours' => 60, 'days' => 1440 }.freeze
  MAX_COMPENSATION_MINUTES = 30 * 1440

  def set_tenant
    @account = Account.find_by(subdomain: request.headers['X-Subdomain'])
    return render json: { error: 'Invalid tenant' }, status: :not_found unless @account

    ActsAsTenant.current_tenant = @account
  end

  def set_time_zone
    Time.zone = GeneralSetting.first&.timezone || Rails.application.config.time_zone
  end

  # GET /api/paid_not_connected/summary  (dashboard banner)
  def summary
    rows = pending_rows(days: 7)
    render json: {
      count: rows.size,
      amount: rows.sum { |r| r[:amount] },
      auto_eligible_count: rows.count { |r| r[:auto_eligible] }
    }
  end

  # GET /api/paid_not_connected?days=7
  def index
    rows = pending_rows(days: days_param)
    render json: {
      default_grace_minutes: grace_minutes,
      rows: rows.map { |r| serialize(r) }
    }
  end

  # POST /api/paid_not_connected/compensate
  # { session_ids: [], mode: 'suggested'|'custom', duration_value:, duration_unit:, notify: false, days: 7 }
  def compensate
    ids = Array(params[:session_ids]).map(&:to_i).uniq
    return render json: { error: 'Select at least one customer' }, status: :unprocessable_entity if ids.empty?

    notify = ActiveModel::Type::Boolean.new.cast(params[:notify]) || false
    rows = pending_rows(days: days_param).select { |r| ids.include?(r[:session].id) }
    return render json: { error: 'None of the selected sessions are pending anymore' }, status: :unprocessable_entity if rows.empty?

    groups =
      if params[:mode] == 'suggested'
        rows.group_by { |r| r[:suggested_minutes] }
      else
        minutes = custom_minutes
        return render json: { error: 'Invalid compensation duration' }, status: :unprocessable_entity unless minutes

        { minutes => rows }
      end

    compensated = 0
    sms_sent = 0

    groups.each do |minutes, group|
      voucher_ids = group.map { |r| r[:voucher_rec]&.id }.compact
      next if voucher_ids.empty?

      result = HotspotIncidentCompensationService
                 .new(@account, minutes.minutes)
                 .compensate(HotspotVoucher.where(id: voucher_ids), notify: notify)

      done = result.voucher_ids
      sms_sent += result.sms_sent_count

      group.each do |r|
        next unless done.include?(r[:voucher_rec]&.id)

        r[:session].update_columns(
          compensation_status: 'compensated',
          compensated_at: Time.current,
          compensated_minutes: minutes
        )
        compensated += 1
      end
    end

    ActivtyLog.create(
      action: 'create', ip: request.remote_ip,
      description: "Compensated #{compensated} paid-not-connected customer(s)#{notify ? ' with SMS' : ' without SMS'}",
      user_agent: request.user_agent,
      user: current_user.username || current_user.email,
      date: Time.current
    )

    render json: {
      compensated_count: compensated,
      sms_sent_count: sms_sent,
      skipped_count: rows.size - compensated
    }
  end

  # POST /api/paid_not_connected/dismiss  { session_ids: [] }
  def dismiss
    ids = Array(params[:session_ids]).map(&:to_i).uniq
    return render json: { error: 'Select at least one customer' }, status: :unprocessable_entity if ids.empty?

    count = TemporarySession.where(id: ids, compensation_status: nil)
                            .update_all(compensation_status: 'dismissed')
    render json: { dismissed_count: count }
  end

  private

  def days_param
    (params[:days] || 7).to_i.clamp(1, 30)
  end

  def custom_minutes
    factor = UNIT_MINUTES[params[:duration_unit].to_s]
    value = params[:duration_value].to_i
    return nil unless factor && value.positive?

    total = value * factor
    total <= MAX_COMPENSATION_MINUTES ? total : nil
  end

  def grace_minutes
    ((GracePeriodSetting.find_by(account_id: @account.id)&.duration || 1.day).to_i / 60).clamp(1, MAX_COMPENSATION_MINUTES)
  end

  # M-Pesa time_paid often arrives as "20261007210713" (yyyymmddHHMMSS)
  def parse_paid_at(revenue)
    raw = revenue.time_paid.to_s
    parsed = raw.match?(/\A\d{14}\z/) ? (Time.zone.strptime(raw, '%Y%m%d%H%M%S') rescue nil) : nil
    parsed || revenue.created_at
  end

  def pending_rows(days:)
    since = days.days.ago

    sessions = TemporarySession
                 .where(connected: [false, nil], compensation_status: nil)
                 .where('created_at > ? AND created_at < ?', since, MIN_AGE_MINUTES.minutes.ago)
                 .order(created_at: :desc)
                 .limit(500)
                 .to_a

    checkout_ids = sessions.map(&:checkout_request_id).compact
    revenues = HotspotMpesaRevenue
                 .where(checkout_request_id: checkout_ids, status: 'Completed')
                 .index_by(&:checkout_request_id)

    # customer retried and got online later -> not a problem anymore
    connected_later = TemporarySession.where(connected: true)
                                      .where('created_at > ?', since)
                                      .group(:phone_number).maximum(:created_at)

    recent_comp = TemporarySession.where(compensation_status: 'compensated')
                                  .where('compensated_at > ?', 30.days.ago)
                                  .group(:phone_number).count

    vouchers = HotspotVoucher.where(voucher: revenues.values.map(&:voucher).compact).index_by(&:voucher)
    grace = grace_minutes

    sessions.filter_map do |s|
      rev = revenues[s.checkout_request_id]
      next unless rev

      later = connected_later[s.phone_number]
      next if later && later > s.created_at

      paid_at = parse_paid_at(rev)
      waited = [((Time.current - paid_at) / 60).round, 0].max
      suggested = [[((waited / 30.0).ceil * 30), 60].max, grace].min
      voucher = vouchers[rev.voucher]
      repeats = recent_comp[s.phone_number].to_i

      reasons = []
      reasons << 'No voucher found' unless voucher
      reasons << 'Zero amount' unless rev.amount.to_f.positive?
      reasons << "Already compensated #{repeats}x in 30 days" if repeats >= MAX_AUTO_PER_30_DAYS

      {
        session: s, revenue: rev, voucher_rec: voucher,
        paid_at: paid_at, waited: waited, suggested_minutes: suggested,
        amount: rev.amount.to_f, repeats: repeats,
        auto_eligible: reasons.empty?, reasons: reasons
      }
    end
  end

  def serialize(r)
    s = r[:session]
    v = r[:voucher_rec]
    {
      id: s.id,
      phone_number: s.phone_number,
      package: s.hotspot_package,
      voucher: r[:revenue].voucher,
      voucher_status: v&.status,
      voucher_expiration: v&.expiration,
      amount: r[:amount],
      mac: s.mac,
      ip: s.ip,
      paid_at: r[:paid_at].in_time_zone.strftime('%d %b %Y, %I:%M %p'),
      minutes_since_paid: r[:waited],
      suggested_minutes: r[:suggested_minutes],
      auto_eligible: r[:auto_eligible],
      reasons: r[:reasons],
      repeat_count: r[:repeats]
    }
  end
end

