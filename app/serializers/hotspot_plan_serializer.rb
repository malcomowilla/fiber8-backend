class HotspotPlanSerializer < ActiveModel::Serializer
  attributes :id,:hotspot_subscribers, :name, :expiry_days, :billing_cycle
  belongs_to :account
end
