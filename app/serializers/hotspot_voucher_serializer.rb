class HotspotVoucherSerializer < ActiveModel::Serializer
  attributes :id, :voucher, :status, :expiration, :speed_limit,
   :phone, :package, :shared_users,
  :created_at, :updated_at, :ip, :mac, :last_logged_in, :sms_sent,
  :payment_method, :reference, :amount, :customer, :time_paid, :account_id


  
def last_logged_in
  object.last_logged_in.strftime("%B %d, %Y at %I:%M %p") if object.last_logged_in.present?

end

  # expiration_time&.strftime("%B %d, %Y at %I:%M %p")
def expiration
  object.expiration.strftime("%B %d, %Y at %I:%M %p") if object.expiration.present?
end


def time_paid
  revenue = object.hotspot_mpesa_revenue
  return unless revenue&.time_paid.present?

  # M-Pesa format string: "20260124133744"
  Time.zone.strptime(revenue.time_paid, "%Y%m%d%H%M%S")
      .strftime("%B %d, %Y at %I:%M %p")
end

def payment_method
  object.hotspot_mpesa_revenue&.payment_method
end

def reference
  object.hotspot_mpesa_revenue&.reference
end

def amount
  object.hotspot_mpesa_revenue&.amount
end

def customer
  object.hotspot_mpesa_revenue&.name
end

# Return the shared users of the hotspot package.
# If the package is not found or if it does not have shared users,
# return "Unlimited".
def shared_users
  # Find the hotspot package by its name.
  package = self.object.hotspot_package

  # If the package is found and it has shared users, return the shared users.
  if package && package.shared_users
    package.shared_users
  else
    # If the package is not found or if it does not have shared users, return "Unlimited".
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
  package = self.object.hotspot_package

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







