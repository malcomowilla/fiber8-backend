class AddCompanyNameToHotspotPlan < ActiveRecord::Migration[7.2]
  def change
    add_column :hotspot_plans, :company_name, :string
  end
end
