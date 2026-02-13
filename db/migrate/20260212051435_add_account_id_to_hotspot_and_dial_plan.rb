class AddAccountIdToHotspotAndDialPlan < ActiveRecord::Migration[7.2]
  def change
    add_column :hotspot_and_dial_plans, :account_id, :integer
  end
end
