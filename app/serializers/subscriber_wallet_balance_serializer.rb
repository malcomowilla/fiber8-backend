class SubscriberWalletBalanceSerializer < ActiveModel::Serializer
  attributes :id, :amount, :account_id, :subscriber_id
end
