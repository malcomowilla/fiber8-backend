# app/models/tv_plan.rb

class TvPlan < ApplicationRecord
  acts_as_tenant :account
  
  # ═══════════════════════════════════════════════════════════════
  # ASSOCIATIONS
  # ═══════════════════════════════════════════════════════════════
  
  belongs_to :nas_router, optional: true  # ✅ Router for this TV plan
  has_many :tv_subscriptions, dependent: :nullify
  
  # ═══════════════════════════════════════════════════════════════
  # VALIDATIONS
  # ═══════════════════════════════════════════════════════════════
  
  validates :name, presence: true, uniqueness: { scope: :account_id }
  validates :price, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :validity, presence: true, numericality: { greater_than: 0 }
  validates :validity_period_units, presence: true, inclusion: { in: %w(minutes hours days weeks months years) }
  validates :download_limit, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true
  validates :upload_limit, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true
  validates :nas_router_id, numericality: { only_integer: true }, allow_nil: true
  
  # ═══════════════════════════════════════════════════════════════
  # SCOPES
  # ═══════════════════════════════════════════════════════════════
  
  scope :active, -> { where(active: true) }
  scope :ordered, -> { order(:position, :id) }
  scope :by_router, ->(router_id) { where(nas_router_id: router_id) }
  
  # ═══════════════════════════════════════════════════════════════
  # CALLBACKS
  # ═══════════════════════════════════════════════════════════════
  
  before_save :validate_router_exists, if: -> { nas_router_id_changed? }
  
  # ═══════════════════════════════════════════════════════════════
  # METHODS
  # ═══════════════════════════════════════════════════════════════
  
  def router_name
    nas_router&.name
  end
  
  def router_ip
    nas_router&.ip_address
  end
  
  def has_router?
    nas_router.present?
  end
  
  # Format for API response
  def to_api_json
    {
      id: id,
      name: name,
      price: price,
      validity: validity,
      validity_period_units: validity_period_units,
      download_limit: download_limit,
      upload_limit: upload_limit,
      active: active,
      position: position,
      nas_router_id: nas_router_id,
      router_name: router_name,
      router_ip: router_ip,
      created_at: created_at,
      updated_at: updated_at
    }
  end
  
  private
  
  def validate_router_exists
    if nas_router_id.present? && !NasRouter.exists?(id: nas_router_id)
      errors.add(:nas_router_id, "Router not found")
    end
  end
end

# ═══════════════════════════════════════════════════════════════
# # app/models/hotspot_setting.rb

# class HotspotSetting < ApplicationRecord
#   acts_as_tenant :account
  
#   # ═══════════════════════════════════════════════════════════════
#   # ASSOCIATIONS
#   # ═══════════════════════════════════════════════════════════════
  
#   belongs_to :account, optional: true
  
#   # ═══════════════════════════════════════════════════════════════
#   # VALIDATIONS
#   # ═══════════════════════════════════════════════════════════════
  
#   validates :display_tv_plans, inclusion: { in: [true, false] }
#   validates :display_wifi_plans, inclusion: { in: [true, false] }
#   validates :display_pppoe_plans, inclusion: { in: [true, false] }
  
#   # ═══════════════════════════════════════════════════════════════
#   # SCOPES & METHODS
#   # ═══════════════════════════════════════════════════════════════
  
#   def self.current
#     first || create!
#   end
  
#   def toggle_tv_plans
#     update(display_tv_plans: !display_tv_plans)
#   end
  
#   def toggle_wifi_plans
#     update(display_wifi_plans: !display_wifi_plans)
#   end
  
#   def toggle_pppoe_plans
#     update(display_pppoe_plans: !display_pppoe_plans)
#   end
# end

# # ═══════════════════════════════════════════════════════════════
# # app/models/nas_router.rb

# class NasRouter < ApplicationRecord
#   acts_as_tenant :account
  
#   # ═══════════════════════════════════════════════════════════════
#   # ASSOCIATIONS
#   # ═══════════════════════════════════════════════════════════════
  
#   has_many :tv_plans, dependent: :nullify      # ✅ TV plans using this router
#   has_many :packages, dependent: :nullify      # PPPoE packages
#   has_many :ip_bindings, dependent: :destroy   # Device IP bindings
  
#   # ═══════════════════════════════════════════════════════════════
#   # VALIDATIONS
#   # ═══════════════════════════════════════════════════════════════
  
#   validates :name, presence: true, uniqueness: { scope: :account_id }
#   validates :ip_address, presence: true, uniqueness: { scope: :account_id }
  
#   # ═══════════════════════════════════════════════════════════════
#   # METHODS
#   # ═══════════════════════════════════════════════════════════════
  
#   def tv_plans_count
#     tv_plans.count
#   end
  
#   def pppoe_packages_count
#     packages.where(type: 'PPPoEPackage').count
#   end
# end