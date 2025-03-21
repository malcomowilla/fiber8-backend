class SystemMetric < ApplicationRecord
  acts_as_tenant(:account)
end
