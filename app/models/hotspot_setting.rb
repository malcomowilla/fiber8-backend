class HotspotSetting < ApplicationRecord
  has_one_attached :hotspot_banner
  acts_as_tenant(:account)

  
end
