class AddLogoToCompanySettings < ActiveRecord::Migration[7.1]
  def change
    add_column :company_settings, :logo, :string
  end
end
