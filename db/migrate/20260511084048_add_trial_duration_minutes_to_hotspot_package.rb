class AddTrialDurationMinutesToHotspotPackage < ActiveRecord::Migration[7.2]
  def change
    add_column :hotspot_packages, :free_trial_duration_minutes, :string
  end
end
