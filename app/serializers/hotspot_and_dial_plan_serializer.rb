class HotspotAndDialPlanSerializer < ActiveModel::Serializer
  attributes :id, :expiry, :status, :expiry_days, :company_name, :name


  def company_name
   return nil unless object.account.present?
   
   object.account.subdomain
  
end

  # def expiry
  #   object.expiry.strftime("%B %d, %Y at %I:%M %p") if object.expiry.present?
  # end

def expiry
    return nil unless object.expiry.present?
    
    object.expiry.strftime("%B %d, %Y at %I:%M %p") if object.expiry.present?

end



def status

if object.expiry.present? && object.expiry < Time.current 
  'expired'
else

  'active'
end
end

end
