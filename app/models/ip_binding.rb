class IpBinding < ApplicationRecord
      acts_as_tenant(:account)

end
