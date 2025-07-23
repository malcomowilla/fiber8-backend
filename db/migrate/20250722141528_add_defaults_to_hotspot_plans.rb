class AddDefaultsToHotspotPlans < ActiveRecord::Migration[7.2]
  def change
     change_column_default :hotspot_plans, :status, from: nil, to: 'active'
    change_column_default :hotspot_plans, :price, from: nil, to: '0'
    change_column_default :hotspot_plans, :hotspot_subscribers, from: nil, to: 'unlimited'
    change_column_default :hotspot_plans, :name, from: nil, to: 'Free Trial'
  end
end
