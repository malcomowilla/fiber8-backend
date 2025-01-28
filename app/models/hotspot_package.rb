class HotspotPackage < ApplicationRecord
  acts_as_tenant(:account)

validates :name, presence: true, uniqueness: true

end
