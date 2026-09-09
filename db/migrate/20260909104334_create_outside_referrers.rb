class CreateOutsideReferrers < ActiveRecord::Migration[7.2]
   def change
    create_table :outside_referrers do |t|
      t.string :name, null: false
      t.string :email, null: false
      t.string :phone_number, null: false
      t.string :password_digest, null: false
      t.string :referral_code, null: false
      t.string :status, default: 'active'

      t.timestamps
    end

    add_index :outside_referrers, :email, unique: true
    add_index :outside_referrers, :phone_number, unique: true
    add_index :outside_referrers, :referral_code, unique: true
  end
end
