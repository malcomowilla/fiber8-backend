class CollectorCustomer < ApplicationRecord
  acts_as_tenant(:account, require_tenant: true)

  belongs_to :collector_building
  has_many :collector_transactions, dependent: :nullify

  validates :name, :unit, presence: true
  validate :building_is_in_my_account

  def as_row
    { id: id, name: name, phone: phone, buildingId: collector_building_id, unit: unit, packs: packs_paid }
  end

  private

  # the tenant scope means this only finds buildings of the current account
  def building_is_in_my_account
    errors.add(:collector_building_id, "is invalid") unless CollectorBuilding.exists?(collector_building_id)
  end
end