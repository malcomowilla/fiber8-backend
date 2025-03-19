class HotspotMpesaSettingSerializer < ActiveModel::Serializer
  attributes :id, :account_type, :short_code, :consumer_key, :consumer_secret, :passkey,
  :created_at, :updated_at
end


