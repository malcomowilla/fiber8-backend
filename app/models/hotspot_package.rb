class HotspotPackage < ApplicationRecord
validates :name, presence: true, uniqueness: true
acts_as_tenant(:account)

end
