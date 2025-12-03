class HotspotMpesaRevenueSerializer < ActiveModel::Serializer
  attributes :id, :voucher, :payment_method, :amount, :reference, :time_paid, :account_id


def time_paid
  object.time_paid.strftime("%d %b %Y %H:%M:%S")
end


end
