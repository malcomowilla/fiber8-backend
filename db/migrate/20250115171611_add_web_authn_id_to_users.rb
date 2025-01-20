class AddWebAuthnIdToUsers < ActiveRecord::Migration[7.1]
  def change
    add_column :users, :webauthn_id, :string
    add_column :users, :webauthn_authenticator_attachment, :jsonb
  end
end
