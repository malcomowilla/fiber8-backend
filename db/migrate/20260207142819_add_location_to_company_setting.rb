class AddLocationToCompanySetting < ActiveRecord::Migration[7.2]
  def change
    add_column :company_settings, :location, :string
  end
end
