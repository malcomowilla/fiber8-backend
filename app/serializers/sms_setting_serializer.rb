class SmsSettingSerializer < ActiveModel::Serializer
  
  attributes :id, :api_key, :api_secret, :sender_id, :short_code, :username, :account_id, :sms_provider,
  :created_at, :updated_at,  :partnerID, :sms_setting_updated_at


  def updated_at
    
    object.updated_at.strftime("%B %d, %Y at %I:%M %p") if object.updated_at.present?


  end


def sms_setting_updated_at
  object.sms_setting_updated_at.strftime("%B %d, %Y at %I:%M %p") if object.sms_setting_updated_at.present?

end


  def created_at
    
    object.created_at.strftime("%B %d, %Y at %I:%M %p") if object.created_at.present?
    
  end

end







