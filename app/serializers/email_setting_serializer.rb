class EmailSettingSerializer < ActiveModel::Serializer
  attributes :id, :smtp_host, :smtp_username, :sender_email, :smtp_password, :api_key, :domain,
  :smtp_port
end
