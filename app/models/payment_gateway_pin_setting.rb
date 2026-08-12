# app/models/payment_gateway_pin_setting.rb
#
# One row per tenant. Presence of a non-blank pin_digest is what makes the
# payment settings pages (Tuma, M-Pesa, etc.) require verification at all —
# see PaymentGatewayVerifiable. Deleting this row, or blanking pin_digest,
# turns the restriction off entirely for that tenant.
class PaymentGatewayPinSetting < ApplicationRecord
  belongs_to :account

  has_secure_password :pin, validations: false

  validates :pin, format: { with: /\A\d{4,6}\z/, message: 'must be 4 to 6 digits' }, allow_nil: true
end