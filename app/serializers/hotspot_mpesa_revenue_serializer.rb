class HotspotMpesaRevenueSerializer < ActiveModel::Serializer
  attributes :id, :voucher, :payment_method, :amount, :reference, :time_paid, :account_id
end
