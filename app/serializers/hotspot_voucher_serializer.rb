class HotspotVoucherSerializer < ActiveModel::Serializer
  attributes :id, :voucher, :status, :expiration, :speed_limit, :phone, :package, :shared_users 

  # expiration_time&.strftime("%B %d, %Y at %I:%M %p")
def expiration
  object.expiration.strftime("%B %d, %Y at %I:%M %p") if object.expiration.present?
end

 def speed_limit
  upload_limit = HotspotPackage.where(package_name: self.object.package).upload_limit
   download_limit =  HotspotPackage.where(package_name: self.object.package).download_limit

   "#{upload_limit}M/#{download_limit}M" || "Unlimited"

end

def status
  return "expired" if object.expiration.present? && object.expiration < Time.current

  object.status
end
end







