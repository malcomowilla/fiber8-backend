class CreateSystemAdmins < ActiveRecord::Migration[7.1]
  def change
    create_table :system_admins do |t|
      t.string :user_name
      t.string :password_digest
      t.string :email
      t.string :verification_token
      t.boolean :email_verified, default: false
      t.string :role
      t.string :fcm_token
      t.string :webauthn_id
      t.jsonb :webauthn_authenticator_attachment
      t.boolean :login_with_passkey, default: false

      t.timestamps
    end
  end
end
