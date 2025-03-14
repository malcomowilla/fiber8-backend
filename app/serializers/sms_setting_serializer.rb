class SmsSettingSerializer < ActiveModel::Serializer
  
  attributes :id, :api_key, :api_secret, :sender_id, :short_code, :username, :account_id, :sms_provider,
  :created_at, :updated_at,  :partnerID


end







