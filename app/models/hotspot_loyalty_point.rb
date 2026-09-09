# app/models/hotspot_loyalty_point.rb
class HotspotLoyaltyPoint < ApplicationRecord
  acts_as_tenant(:account)
  has_many :hotspot_loyalty_activities
  validates :phone, presence: true, uniqueness: { scope: :account_id }
end