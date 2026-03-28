class AdSetting < ApplicationRecord
  acts_as_tenant(:account)
   has_one_attached :media_file 
end
