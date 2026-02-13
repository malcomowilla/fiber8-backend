class SubscriberTransactionSerializer < ActiveModel::Serializer
  attributes :id, :type, :credit, :debit, :date, :title, :description, :account_id
end
