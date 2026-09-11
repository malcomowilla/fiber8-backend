class PackageRouter < ApplicationRecord
  belongs_to :package
  belongs_to :nas_router
  belongs_to :ip_pool
end




