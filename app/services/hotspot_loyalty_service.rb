class HotspotLoyaltyService
  def self.award_points(account_id:, phone:, amount:, name: nil, package: nil, reference: nil)
    return unless phone.present? && amount.to_f > 0

    setting = HotspotLoyaltySetting.find_by(account_id: account_id)
    return unless setting&.enabled

    # Don't double-award on M-Pesa/Tuma callback retries
    if reference.present? &&
       HotspotLoyaltyActivity.exists?(account_id: account_id, reference: reference, kind: 'earn')
      return
    end

    phone = normalize_phone(phone)

    record = HotspotLoyaltyPoint.find_or_create_by!(account_id: account_id, phone: phone) do |r|
      r.first_seen_at = Time.current
    end

    points_earned = ((amount.to_f * setting.earn_rate_percent.to_f) / 100.0).round
    return if points_earned <= 0
    return if setting.max_points.present? && record.balance >= setting.max_points # paused at cap

    new_balance = record.balance + points_earned
    new_balance = setting.max_points if setting.max_points.present? && new_balance > setting.max_points
    actual_earned = new_balance - record.balance
    return if actual_earned <= 0

    record.update!(
      balance: new_balance,
      lifetime_earned: record.lifetime_earned + actual_earned,
      total_spent_amount: record.total_spent_amount + amount.to_f,
      purchase_count: record.purchase_count + 1,
      last_package: package.presence || record.last_package,
      last_purchase_at: Time.current,
      name: name.presence || record.name,
      expiry_warning_sent: false
    )

    HotspotLoyaltyActivity.create!(
      account_id: account_id,
      hotspot_loyalty_point_id: record.id,
      kind: 'earn',
      points: actual_earned,
      balance_after: new_balance,
      amount: amount,
      package: package,
      reference: reference
    )
  rescue => e
    Rails.logger.error "HotspotLoyaltyService.award_points failed: #{e.message}"
  end

  def self.normalize_phone(phone)
    phone = phone.to_s.strip
    return phone if phone.start_with?('0')
    phone.start_with?('254') ? "0#{phone[3..]}" : phone
  end
end