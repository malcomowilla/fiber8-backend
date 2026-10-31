class CreateAccessApplications < ActiveRecord::Migration[7.2]
  def change
    create_table :access_applications do |t|
      t.string   :name,             null: false
      t.string   :company_name,     null: false
      t.string   :subdomain,        null: false
      t.string   :email,            null: false
      t.datetime :email_verified_at
      t.string   :country
      t.string   :phone_number,     null: false
      t.string   :support_whatsapp
      t.string   :referral_code
      t.string   :status,           null: false, default: 'pending' # pending | approved | rejected
      t.string   :rejection_reason
      t.datetime :terms_accepted_at
      t.datetime :reviewed_at
      t.bigint   :account_id
      t.string   :signup_ip
      t.timestamps
    end
    add_index :access_applications, :subdomain
    add_index :access_applications, :email
    add_index :access_applications, :status
  end
end
