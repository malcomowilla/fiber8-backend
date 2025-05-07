class HotspotPlan < ApplicationRecord
  acts_as_tenant(:account)

  # has_many :accounts

end
