class CreateSystemAdminWebAuthnCredentials < ActiveRecord::Migration[7.1]
  def change
    create_table :system_admin_web_authn_credentials do |t|
      t.string :webauthn_id
      t.string :public_key
      t.integer :sign_count
      t.integer :system_admin_id

      t.timestamps
    end
  end
end
