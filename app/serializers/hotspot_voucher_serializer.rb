class HotspotVoucherSerializer < ActiveModel::Serializer
  attributes :id, :voucher, :status, :expiration, :speed_limit,
   :phone, :package, :shared_users,
  :created_at, :updated_at, :ip, :mac, :last_logged_in, :sms_sent,
  :payment_method, :reference, :amount, :customer, :time_paid


  
def last_logged_in
  object.last_logged_in.strftime("%B %d, %Y at %I:%M %p") if object.last_logged_in.present?

end

  # expiration_time&.strftime("%B %d, %Y at %I:%M %p")
def expiration
  object.expiration.strftime("%B %d, %Y at %I:%M %p") if object.expiration.present?
end



  # def time_paid
  #   return unless object.hotspot_mpesa_revenue&.time_paid.present?

  #   Time.zone.strptime(object.hotspot_mpesa_revenue.time_paid, "%Y%m%d%H%M%S")
  #           .strftime("%B %d, %Y at %I:%M %p")
  # end

  # def time_paid
  #   object.hotspot_mpesa_revenue&.time_paid&.strftime("%B %d, %Y at %I:%M %p")
  # end

  # def payment_method
  #   object.hotspot_mpesa_revenue&.payment_method
  # end

  # def reference
  #   object.hotspot_mpesa_revenue&.reference
  # end

  # def amount
  #   object.hotspot_mpesa_revenue&.amount
  # end

  # def customer
  #   object.hotspot_mpesa_revenue&.name
  # end

def shared_users
  package = HotspotPackage.find_by(name: self.object.package)
  if package && package.shared_users
    package.shared_users
  else
    "Unlimited"
  end
end





def created_at
  object.created_at.strftime("%B %d, %Y at %I:%M %p") if object.created_at.present?
end


def updated_at
  object.updated_at.strftime("%B %d, %Y at %I:%M %p") if object.updated_at.present?
end



 def speed_limit
  package = HotspotPackage.find_by(name: self.object.package)

  if package && package.upload_limit && package.download_limit
    "#{package.upload_limit}M/#{package.download_limit}M"
  else
    "Unlimited"
  end
end

# def status
#   return "expired" if object.expiration.present? && object.expiration < Time.current

#   object.status
# end
end







