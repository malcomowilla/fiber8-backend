class AdSetting < ApplicationRecord
  acts_as_tenant(:account)
   has_one_attached :media_file 
   has_many :ad_events, dependent: :destroy
end
