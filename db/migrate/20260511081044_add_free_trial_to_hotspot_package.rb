class AddFreeTrialToHotspotPackage < ActiveRecord::Migration[7.2]
  def change
    add_column :hotspot_packages, :enable_free_trial, :boolean
    add_column :hotspot_packages, :free_trial_duration_minutes, :boolean
    add_column :hotspot_packages, :free_trial_download_limit, :string
    add_column :hotspot_packages, :free_trial_upload_limit, :string
  end
end
