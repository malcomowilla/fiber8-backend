class DialUpMpesaSettingSerializer < ActiveModel::Serializer
  attributes :id, :account_type, :short_code, :consumer_key, :consumer_secret, :passkey
end
