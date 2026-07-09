class HotspotSetting < ApplicationRecord
  has_one_attached :hotspot_banner
  acts_as_tenant(:account)
  has_one_attached :design_logo   # new

  
end
