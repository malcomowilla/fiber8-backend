class PpPoeMpesaRevenueSerializer < ActiveModel::Serializer
  attributes :id, :payment_method, :amount, :reference,
   :time_paid, :account_id, :account_number, :payment_type,
   :customer_name

def time_paid
 object.time_paid.strftime("%B %d, %Y at %I:%M %p")
end



end





