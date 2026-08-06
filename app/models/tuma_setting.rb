# app/models/tuma_setting.rb
class TumaSetting < ApplicationRecord
  acts_as_tenant(:account)
  belongs_to :account

  validates :business_email, presence: true, if: :enabled?
  validates :api_key, presence: true, if: :enabled?

  TOKEN_LEEWAY = 5.minutes

  def token_valid?
    cached_token.present? && token_expires_at.present? &&
      token_expires_at > Time.current + TOKEN_LEEWAY
  end
end