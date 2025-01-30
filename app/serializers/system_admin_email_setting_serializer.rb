class SystemAdminEmailSettingSerializer < ActiveModel::Serializer
  attributes :id, :smtp_host, :smtp_username, :sender_email, :smtp_password, :api_keydomain, :system_admin_id
end
