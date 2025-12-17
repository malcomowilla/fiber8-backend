class HotspotVoucherSerializer < ActiveModel::Serializer
  attributes :id, :voucher, :status, :expiration, :speed_limit, :phone, :package, :shared_users,
  :created_at, :updated_at

  # expiration_time&.strftime("%B %d, %Y at %I:%M %p")
def expiration
  object.expiration.strftime("%B %d, %Y at %I:%M %p") if object.expiration.present?
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

def status
  return "expired" if object.expiration.present? && object.expiration < Time.current

  object.status
end
end







