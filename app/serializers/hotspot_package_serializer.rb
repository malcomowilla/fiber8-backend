class HotspotPackageSerializer < ActiveModel::Serializer
  attributes :id, :name, :price, :download_limit, :upload_limit, :account_id, :tx_rate_limit, :rx_rate_limit, 
  :validity_period_units, :download_burst_limit, :upload_burst_limit, :validity, :speed, :valid,
  :valid_from, :valid_until, :weekdays, :location, :package_speed,
   :burst_enabled,
    :burst_limit_download, :sync_status,
    :burst_limit_upload, :synced_at,
    :burst_threshold_download, :sync_error,
    :burst_threshold_upload,
    :burst_time,
    :enable_free_trial,
    :free_trial_duration_minutes,
    :free_trial_download_limit,
    :free_trial_upload_limit,
    :nas_router,
    :intended_device_type,
      :device_icon,
      :shared_users     







  def name
    object.download_limit == '' ? "Unlimited #{object.name}": object.name
  end


def shared_users
  return unless object.shared_users.present?

  "#{object.shared_users.to_i}-Device"
end
  



  def valid_from
    object.valid_from.strftime('%I:%M %p') if object.valid_from.present?
  end

  def valid_until
    object.valid_until.strftime('%I:%M %p') if object.valid_until.present?
  end

  def package_speed
    "#{self.object.upload_limit}M/#{self.object.download_limit}M" if self.object.upload_limit && self.object.download_limit
  end
  
  

  def speed
     if self.object.download_limit then "#{self.object.download_limit}Mbps" else "unlimited" end
  end
  

  
  # def speed
  #   "#{self.object.upload_limit}M/#{self.object.download_limit}M" 
  # end

  # def valid
  #   self.object.validity_period_units == 'days' ? "#{self.object.validity}days" : "#{self.object.validity}hour"
  
    
  # end

  def valid
    case self.object.validity_period_units
    when 'days'
      "#{self.object.validity} days"
    when 'hours' 
      "#{self.object.validity} hours"
    when 'minutes'
      "#{self.object.validity} minutes"
    else
      nil # Return nil if no match is found
    end
  end


  
  
  
end
