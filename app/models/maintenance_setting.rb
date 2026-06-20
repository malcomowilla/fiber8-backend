class MaintenanceSetting < ApplicationRecord
  belongs_to :account

  # Scoped to current tenant via acts_as_tenant if desired, or find by account
end