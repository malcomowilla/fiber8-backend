class SmsProviderSettingSerializer < ActiveModel::Serializer
  attributes :id, :sms_provider, :account_id
end
