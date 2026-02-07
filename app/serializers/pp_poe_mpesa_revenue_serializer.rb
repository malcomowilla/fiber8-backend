class PpPoeMpesaRevenueSerializer < ActiveModel::Serializer
  attributes :id, :payment_method, :amount, :reference,
   :time_paid, :account_id, :account_number, :payment_type

def time_paid
Time.zone.strptime(object.time_paid, "%Y%m%d%H%M%S").strftime("%B %d, %Y at %I:%M %p")

end

end





