class HotspotCustomizationSerializer < ActiveModel::Serializer
  attributes :id, :customize_template_and_package_per_location, 
  :enable_autologin, :compensation_minutes, :compensation_hours,
  :enable_compensation, :enable_free_trial,
    :free_trial_duration_minutes,
    :free_trial_download_limit,
    :free_trial_upload_limit
end




