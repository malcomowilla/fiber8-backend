class HotspotMpesaRevenueSerializer < ActiveModel::Serializer
  attributes :id, :voucher, :payment_method, :amount, :reference, :time_paid, :account_id


def time_paid
    Time.strptime(object.time_paid, "%Y%m%d%H%M%S").strftime("%d %b %Y %H:%M:%S")

end


end
