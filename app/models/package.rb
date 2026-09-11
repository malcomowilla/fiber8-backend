class Package < ApplicationRecord
    acts_as_tenant(:account)
    # validates :name,  uniqueness: {case_sensitive: true}
    

     has_many :package_routers, dependent: :destroy
  has_many :nas_routers, through: :package_routers
  has_many :ip_pools, through: :package_routers

  PLAN_TYPES = %w[standard shared dedicated enterprise].freeze

  validates :name, presence: true
  validates :plan_type, inclusion: { in: PLAN_TYPES }
  validates :download_limit, :upload_limit, :price, :validity, presence: true

  accepts_nested_attributes_for :package_routers, allow_destroy: true

  def effective_profile_name
    router_profile_name.presence || name
  end
end



