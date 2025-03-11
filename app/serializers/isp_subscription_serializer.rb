class IspSubscriptionSerializer < ActiveModel::Serializer
  attributes :id, :account_id, :next_billing_date, :payment_status, :plan_name, :features, :renewal_period, :last_payment_date
end
