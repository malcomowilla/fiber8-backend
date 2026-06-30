class PpPoeMpesaRevenueSerializer < ActiveModel::Serializer
  attributes :id, :payment_method, :amount, :reference,
   :time_paid, :account_id, :account_number, :payment_type,
   :customer_name,  :paid_out, :paid_out_at, 
  :amount_disbursed, :status

# def time_paid
#  object.time_paid.strftime("%B %d, %Y at %I:%M %p")
# end


def time_paid
  return nil if object.time_paid.blank?

  Time.strptime(object.time_paid, "%Y%m%d%H%M%S")
      .strftime("%d %b %Y %I:%M %p")
end

end
