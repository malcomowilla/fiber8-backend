json.extract! system_admin, :id, :user_name, :password_digest, :email, :verification_token, :email_verified, :role, :fcm_token, :webauthn_id, :webauthn_authenticator_attachment, :login_with_passkey, :created_at, :updated_at
json.url system_admin_url(system_admin, format: :json)
