class DialMpesaSettingSerializer < ActiveModel::Serializer
  attributes :id, :account_id, :account_type, :short_code, :consumer_key, :consumer_secret, :passkey
end
