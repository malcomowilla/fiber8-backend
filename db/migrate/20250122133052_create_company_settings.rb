class CreateCompanySettings < ActiveRecord::Migration[7.1]
  def change
    create_table :company_settings do |t|
      t.string :company_name
      t.string :email_info
      t.string :contact_info
      t.string :agent_email
      t.string :customer_support_phone_number
      t.string :customer_support_email

      t.timestamps
    end
  end
end
