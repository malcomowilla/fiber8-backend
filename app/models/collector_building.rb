class CollectorBuilding < ApplicationRecord
  acts_as_tenant(:account)

  has_many :collector_customers, dependent: :restrict_with_error

  validates :name, :area, presence: true
  validates :units, numericality: { only_integer: true, greater_than: 0 }, allow_nil: true

  def as_row
    { id: id, name: name, area: area, units: units }
  end
end



