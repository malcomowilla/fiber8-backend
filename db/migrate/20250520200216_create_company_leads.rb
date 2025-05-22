class CreateCompanyLeads < ActiveRecord::Migration[7.2]
  def change
    create_table :company_leads do |t|
      t.string :name
      t.string :company_name
      t.string :email
      t.string :message
      t.integer :account_id

      t.timestamps
    end
  end
end
