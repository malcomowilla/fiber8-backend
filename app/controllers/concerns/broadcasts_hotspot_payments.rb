# frozen_string_literal: true

# Include in any controller that finalizes a hotspot payment (voucher or
# TV/device-binding purchase) so the dashboard sees it the instant it lands.
module BroadcastsHotspotPayments
  extend ActiveSupport::Concern

  private

  def broadcast_hotspot_payment(account_id:, kind:, amount:, package: nil,
                                 name: nil, phone: nil, payment_method: 'Mpesa',
                                 reference: nil)
    return if account_id.blank?

    ActionCable.server.broadcast(
      "hotspot_payments_#{account_id}",
      {
        id: reference.presence || SecureRandom.uuid,
        kind: kind, # 'voucher' or 'tv_plan'
        amount: amount.to_f,
        package: package,
        name: name,
        phone: phone,
        payment_method: payment_method,
        reference: reference,
        created_at: Time.current.iso8601
      }
    )
  rescue => e
    Rails.logger.warn "broadcast_hotspot_payment failed: #{e.message}"
  end
end