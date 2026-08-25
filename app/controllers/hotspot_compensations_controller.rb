class HotspotCompensationsController < ApplicationController
  set_current_tenant_through_filter
  before_action :set_tenant

  def set_tenant
    host = request.headers['X-Subdomain']
    @account = Account.find_by(subdomain: host)
    ActsAsTenant.current_tenant = @account
  rescue ActiveRecord::RecordNotFound
    render json: { error: 'Invalid tenant' }, status: :not_found
  end

  # POST /api/hotspot_compensations/bulk
  # { phone_numbers: [...], grace_value: 1, grace_unit: 'days', notify: true, expired_lookback_days: 3 }
  def bulk
    phone_numbers = Array(params[:phone_numbers]).map(&:to_s).map(&:strip).reject(&:blank?)
    return render json: { error: 'No phone numbers provided' }, status: :unprocessable_entity if phone_numbers.empty?

    grace_duration = build_duration(params[:grace_value], params[:grace_unit])
    lookback_days = params[:expired_lookback_days].presence&.to_i || 3
    cutoff = Time.current - lookback_days.days

    vouchers = HotspotVoucher.where(account_id: @account.id, phone: phone_numbers)
                              .where('status = ? OR (status = ? AND expiration >= ?)', 'active', 'expired', cutoff)

    return render json: { error: 'No matching (recent) vouchers found for the given numbers' }, status: :not_found if vouchers.empty?

    notify = ActiveModel::Type::Boolean.new.cast(params[:notify].nil? ? true : params[:notify])
    result = HotspotIncidentCompensationService.new(@account, grace_duration).compensate(vouchers, notify: notify)

    ActivtyLog.create(
      action: 'compensate', ip: request.remote_ip,
      description: "Bulk-compensated #{result.compensated_count} hotspot voucher(s) manually",
      user_agent: request.user_agent, user: current_user.username || current_user.email,
      date: Time.current
    )

    render json: { compensated_count: result.compensated_count, sms_sent_count: result.sms_sent_count }
  end

  private

  def build_duration(value, unit)
    value = value.to_i
    value = 1 if value <= 0
    case unit
    when 'minutes' then value.minutes
    when 'hours'   then value.hours
    else value.days
    end
  end
end