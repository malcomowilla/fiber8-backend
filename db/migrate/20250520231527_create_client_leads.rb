class CreateClientLeads < ActiveRecord::Migration[7.2]
  def change
    create_table :client_leads do |t|
      t.string :name
      t.string :email
      t.string :company_name
      t.string :phone_number

      t.timestamps
    end
  end
end
