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


def time_paid
  time_paid = HotspotMpesaRevenue.find_by(voucher: self.object.voucher)
   time_paid&.time_paid&.strftime("%B %d, %Y at %I:%M %p") if time_paid&.time_paid.present?
  
end


def payment_method
  payment_method = HotspotMpesaRevenue.find_by(voucher: self.object.voucher)
  payment_method&.payment_method if payment_method&.payment_method.present?
  
end



def reference
  reference =  HotspotMpesaRevenue.find_by(voucher: self.object.voucher)
  reference&.reference if reference&.reference.present?
  
end


def amount
  amount = HotspotMpesaRevenue.find_by(voucher: self.object.voucher)
  amount&.amount if amount&.amount.present?
  
end


def customer
  customer = HotspotMpesaRevenue.find_by(voucher: self.object.voucher)
  customer&.name if customer&.name.present?
  
end



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







