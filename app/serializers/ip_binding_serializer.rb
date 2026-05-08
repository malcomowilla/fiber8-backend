class IpBindingSerializer < ActiveModel::Serializer
  attributes :id, :router, :name, :package, :mac, :ip, :expiry, :device_type,
   :account_id, :router_id, :created_at, :expiry









  def created_at
    object.created_at.strftime("%B %d, %Y at %I:%M %p") if object.created_at.present?
    
  end




end
