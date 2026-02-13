class HotspotPlanSerializer < ActiveModel::Serializer
  attributes :id,:hotspot_subscribers, :name, :expiry_days, 
  :billing_cycle, :expiry, :status,
  :condition, :company_name
  
  # belongs_to :account


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

   

   

  # def condition
  #   return false unless object.expiry.present?
    
  #   # Get warning days threshold from frontend settings or use default (2 days)
  #   warning_days = object.account.license_setting&.expiry_warning_days || 2
    
  #   # Check if expiry is within the warning period
  #   (object.expiry - Time.current) <= warning_days.days
  # end


  def status
    # return "expired" if object.expiry.present? && object.expiry < Time.current 

if object.expiry.present? && object.expiry < Time.current 
  'expired'
else

  'active'
end
    # object.status
  end








  

end











