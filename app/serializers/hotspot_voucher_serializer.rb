class HotspotVoucherSerializer < ActiveModel::Serializer
  attributes :id, :voucher, :status, :expiration, :speed_limit, :phone, :package

  # expiration_time&.strftime("%B %d, %Y at %I:%M %p")
def expiration
  object.expiration.strftime("%B %d, %Y at %I:%M %p") if object.expiration.present?
end

end
