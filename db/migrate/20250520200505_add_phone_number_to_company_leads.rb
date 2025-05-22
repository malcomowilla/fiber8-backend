class AddPhoneNumberToCompanyLeads < ActiveRecord::Migration[7.2]
  def change
    add_column :company_leads, :phone_number, :string
  end
end
