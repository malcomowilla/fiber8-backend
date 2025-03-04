class HotspotSubscription < ApplicationRecord

  acts_as_tenant(:account)

end



