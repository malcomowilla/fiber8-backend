class CreateCompanyIds < ActiveRecord::Migration[7.2]
  def change
    create_table :company_ids do |t|
      t.string :company_id
      t.integer :account_id

      t.timestamps
    end
  end
end
