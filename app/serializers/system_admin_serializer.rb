class SystemAdminSerializer < ActiveModel::Serializer
  attributes :id, :user_name, :email, :verification_token,
   :email_verified, :role, :fcm_token, :webauthn_id, 
   :webauthn_authenticator_attachment, :login_with_passkey, :phone_number





  #  :phone_number_verified,
end
