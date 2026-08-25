class AddSlaThresholdHoursToGracePeriodSettings < ActiveRecord::Migration[7.2]
 def change
    add_column :grace_period_settings, :sla_threshold_hours, :integer, default: 24, null: false
  end
end
