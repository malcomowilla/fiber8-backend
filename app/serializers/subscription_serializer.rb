class SubscriptionSerializer < ActiveModel::Serializer
  attributes :id, :name, :phone, :package, :status, :last_subscribed, :expiry
end
