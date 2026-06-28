class HotspotMpesaRevenueSerializer < ActiveModel::Serializer
  attributes :id, :voucher, :payment_method, :amount, :reference, 
  :time_paid,  :name, :phone_number, :paid_out, :paid_out_at, 
  :amount_disbursed, :status




  # Return the time_paid in the format "%B %d, %Y at %I:%M %p"
# def time_paid
# Time.zone.strptime(object.time_paid, "%Y%m%d%H%M%S").strftime("%B %d, %Y at %I:%M %p")

# end


def time_paid
  return nil if object.time_paid.blank?

  Time.strptime(object.time_paid, "%Y%m%d%H%M%S")
      .strftime("%d %b %Y %I:%M %p")
end

def paid_out_at
    object.paid_out_at.strftime("%B %d, %Y at %I:%M %p") if object.paid_out_at.present?

end


def phone_number
    return object.hotspot_voucher.phone if object.hotspot_voucher.present?
  return object.phone_number if object.phone_number.present?

  "N/A"

end



end


