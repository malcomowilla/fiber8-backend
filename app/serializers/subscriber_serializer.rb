class SubscriberSerializer < ActiveModel::Serializer
  attributes :id, :name, :phone_number, :ppoe_username, :ppoe_password, :email, :ppoe_package, 
  :date_registered, :ref_no,
   :package_name,:installation_fee, :subscriber_discount, :second_phone_number, :router_name,
   :house_number, :building_name, :latitude, :longitude, :expiration, :registration_date,
   :location, :node, :status, :created_at, :updated_at


   def package_name
     object.subscriptions.pluck(:package_name)

   end
   
   def created_at
     
      object.created_at.strftime("%B %d, %Y at %I:%M %p") if object.created_at.present?
   end


   def updated_at
     
      object.updated_at.strftime("%B %d, %Y at %I:%M %p") if object.updated_at.present?
     
   end

   def status
        if self.object.subscriptions.exists?
         self.object.status = 'active'
         else
            self.object.status = 'no subscription'
        end

      
   end



#   def status
    
#   return object.update(status: 'offline'),'offline' if object.subscriptions.empty?

#   threshold_time = 3.minutes.ago

#   online = object.subscriptions.any? do |subscription|
#     next unless subscription.ip_address.present?

#     RadAcct.where(
#       acctstoptime: nil,
#       framedprotocol: 'PPP',
#       framedipaddress: subscription.ip_address
#     ).where('acctupdatetime > ?', threshold_time).exists?
#   end

#   online ? object.update(status: 'online')  : object.update(status: 'offline')
#   object.status 
# end

   def phone_number
    "#{self.object.phone_number}"
   end


   def expiration
    object.expiration.strftime("%B %d, %Y at %I:%M %p") if object.expiration.present?
  end



  def registration_date
     object.registration_date.strftime("%B %d, %Y at %I:%M %p") if object.registration_date.present?
  end



  def date_registered
     object.date_registered.strftime("%B %d, %Y at %I:%M %p") if object.date_registered.present?
  end
  
   def second_phone_number
    "#{self.object.second_phone_number}"

   end
end
