class CreateWalletAudits < ActiveRecord::Migration[7.2]
  def change
    create_table :wallet_audits do |t|
      t.string :admin
      t.string :amount
      t.string :ip_address
      t.string :action
      t.integer :account_id

      t.timestamps
    end
  end
end
