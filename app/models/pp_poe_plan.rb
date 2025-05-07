class PpPoePlan < ApplicationRecord
  # has_many :accounts
  # serialize :features, Array
  acts_as_tenant(:account)
  
end
