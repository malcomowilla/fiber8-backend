class SubscriptionSerializer < ActiveModel::Serializer
  attributes :id, :name, :phone, :package, :status, :last_subscribed, :expiry, :ip_address,
   :ppoe_username, :ppoe_password, :type, :network_name, :validity_period_units, :validity,
   :subscriber_id



   def expiry
    object.expiry.strftime("%B %d, %Y at %I:%M %p") if object.expiry.present?
  end



end
