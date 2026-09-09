# app/models/hotspot_loyalty_activity.rb
class HotspotLoyaltyActivity < ApplicationRecord
  acts_as_tenant(:account)
  belongs_to :hotspot_loyalty_point
end