class OnuSerializer < ActiveModel::Serializer
  attributes :id, :serial_number, :oui, :product_class, :manufacturer, :onu_id, :status, 
  :last_inform, :account_id, :last_boot, :ssid1, :ssid2


def status
  return "offline" unless object.last_inform.present?

  last_inform_time = Time.parse(object.last_inform).in_time_zone("Africa/Nairobi") 
  if last_inform_time > 5.minutes.ago
    "active"
  else
    "offline"
  end
end



 def last_inform
  return unless object.last_inform.present?
  Time.parse(object.last_inform).strftime("%B %d, %Y at %I:%M %p")
end




end


