class AnalyticsEvent < ApplicationRecord
  acts_as_tenant(:account)
end
