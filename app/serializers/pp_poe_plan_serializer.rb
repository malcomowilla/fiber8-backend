class PpPoePlanSerializer < ActiveModel::Serializer
  attributes :id, :maximum_pppoe_subscribers, :name, :expiry_days, :billing_cycle
  belongs_to :account
end
