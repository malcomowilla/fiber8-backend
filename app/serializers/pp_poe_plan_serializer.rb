class PpPoePlanSerializer < ActiveModel::Serializer
  attributes :id, :maximum_pppoe_subscribers, :name, :expiry_days, :billing_cycle, :expiry, :status,
  :condition

  belongs_to :account


  # def expiry
  #   object.expiry.strftime("%B %d, %Y at %I:%M %p") if object.expiry.present?
  # end

def expiry
  if object.expiry.present?
    object.expiry.strftime("%B %d, %Y at %I:%M %p")
  else
    # Use created_at + expiry_days (default to 3 days)
    days = object.expiry_days.presence || 3
    fallback_expiry = object.created_at + days.to_i.days
    fallback_expiry.strftime("%B %d, %Y at %I:%M %p")
  end
end

   def expiry_days
    object.expiry_days.presence || 3
  end

   def maximum_pppoe_subscribers
    object.maximum_pppoe_subscribers.presence || "unlimited"
  end

  def name
 object.name.presence || "Free Trial"

  end

  def condition
    return false unless object.expiry.present?
    
    # Get warning days threshold from frontend settings or use default (2 days)
    warning_days = object.account.license_setting&.expiry_warning_days || 2
    
    # Check if expiry is within the warning period
    (object.expiry - Time.current) <= warning_days.days
  end

  def status
    # return "expired" if object.expiry.present? && object.expiry < Time.current 

if object.expiry.present? && object.expiry < Time.current 
  'expired'
else

  'active'
end

  
  end
end
