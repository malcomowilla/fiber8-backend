class HotspotMpesaRevenueSerializer < ActiveModel::Serializer
  attributes :id, :voucher, :payment_method, :amount, :reference, :time_paid, :account_id


def time_paid
    Time.zone.strptime(object.time_paid, "%Y%m%d%H%M%S").strftime("%B %d, %Y at %I:%M %p")

end


end
