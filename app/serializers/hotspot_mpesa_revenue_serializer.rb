class HotspotMpesaRevenueSerializer < ActiveModel::Serializer
  attributes :id, :voucher, :payment_method, :amount, :reference, 
  :time_paid,  :name, :phone_number


  # Return the time_paid in the format "%B %d, %Y at %I:%M %p"
def time_paid
Time.zone.strptime(object.time_paid, "%Y%m%d%H%M%S").strftime("%B %d, %Y at %I:%M %p")

end


def phone_number
    object.hotspot_voucher&.phone || "N/A"
end

end


