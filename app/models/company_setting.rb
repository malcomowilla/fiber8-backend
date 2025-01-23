class CompanySetting < ApplicationRecord

  acts_as_tenant(:account)
  has_one_attached :logo

end
