class IpBinding < ApplicationRecord
      acts_as_tenant(:account)
belongs_to :tv_plan, optional: true
end
