class AddBurstToPPoePackages < ActiveRecord::Migration[7.1]
  def change
    add_column :p_poe_packages, :download_burst_limit, :string
    add_column :p_poe_packages, :upload_burst_limit, :string
  end
end
