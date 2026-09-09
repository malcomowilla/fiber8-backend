# app/models/hotspot_loyalty_setting.rb
class HotspotLoyaltySetting < ApplicationRecord
  acts_as_tenant(:account)
  validates :earn_rate_percent, numericality: { greater_than_or_equal_to: 0 }
end