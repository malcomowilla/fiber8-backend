class SystemAdminWebAuthnCredentialSerializer < ActiveModel::Serializer
  attributes :id, :webauthn_id, :public_key, :sign_count, :system_admin_id
end
