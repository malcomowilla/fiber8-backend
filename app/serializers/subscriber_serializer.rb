class SubscriberSerializer < ActiveModel::Serializer
  attributes :id, :name, :phone_number, :ppoe_username, :ppoe_password, :email, :ppoe_package, 
  :date_registered, :ref_no,
   :package_name,:installation_fee, :subscriber_discount, :second_phone_number, :router_name,
   :house_number, :building_name, :latitude, :longitude, :expiration, :registration_date,
   :location, :node, :status



   # def status
   #      if self.object.subscriptions.exists?
   #       self.object.status = 'active'
   #       else
   #          self.object.status = 'no subscription'
   #      end

      
   # end



  def status
  return "offline" unless object.subscriptions.any?

  threshold_time = 3.minutes.ago

  online = object.subscriptions.any? do |subscription|
    next unless subscription.ip_address.present?

    RadAcct.exists?(
      acctstoptime: nil,
      framedprotocol: 'PPP',
      framedipaddress: subscription.ip_address
    ).where('acctupdatetime > ?', threshold_time)
  end

  online ? "online" : "offline"
end

   def phone_number
    "#{self.object.phone_number}"
   end


   def expiration
    object.expiration.strftime("%B %d, %Y at %I:%M %p") if object.expiration.present?
  end



  def registration_date
     object.registration_date.strftime("%B %d, %Y at %I:%M %p") if object.registration_date.present?
    
  end
  
   def second_phone_number
    "#{self.object.second_phone_number}"

   end
end
