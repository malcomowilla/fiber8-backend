class AddExpiredLookbackDaysToIncidents < ActiveRecord::Migration[7.2]
  def change
    add_column :incidents, :expired_lookback_days, :integer, default: 3, null: false
  end
end
