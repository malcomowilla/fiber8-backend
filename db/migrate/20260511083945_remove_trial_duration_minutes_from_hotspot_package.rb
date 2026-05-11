class RemoveTrialDurationMinutesFromHotspotPackage < ActiveRecord::Migration[7.2]
  def change
    remove_column :hotspot_packages, :free_trial_duration_minutes, :string
  end
end
