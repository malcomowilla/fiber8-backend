class CreateEmailVerificationCodes < ActiveRecord::Migration[7.2]
  def change
    create_table :email_verification_codes do |t|
      t.string   :email,       null: false
      t.string   :code_digest, null: false
      t.integer  :attempts,    null: false, default: 0
      t.datetime :expires_at,  null: false
      t.timestamps
    end
    add_index :email_verification_codes, :email
  end
end
