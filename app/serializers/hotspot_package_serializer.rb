class HotspotPackageSerializer < ActiveModel::Serializer
  BYTES_PER_MB = 1024**2
  BYTES_PER_GB = 1024**3

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
             :shared_users,
             :enabled,
             :data_limit_bytes,
             :data_limit_value,
             :data_limit_unit,
             :data_limit_label

  def name
    object.download_limit == '' ? "Unlimited #{object.name}" : object.name
  end

  def shared_users
    return unless object.shared_users.present?
    "#{object.shared_users.to_i}"
  end

  def valid_from
    object.valid_from.strftime('%I:%M %p') if object.valid_from.present?
  end

  def valid_until
    object.valid_until.strftime('%I:%M %p') if object.valid_until.present?
  end

  def package_speed
    "#{object.upload_limit}M/#{object.download_limit}M" if object.upload_limit && object.download_limit
  end

  def speed
    object.download_limit ? "#{object.download_limit}Mbps" : "unlimited"
  end

  def valid
    case object.validity_period_units
    when 'days'    then "#{object.validity} days"
    when 'hours'   then "#{object.validity} hours"
    when 'minutes' then "#{object.validity} minutes"
    else nil
    end
  end

  # ── Data limit (stored as bytes, shown as value + unit) ────────────────
  def data_limit_unit
    bytes = object.data_limit_bytes
    return nil if bytes.blank?
    bytes >= BYTES_PER_GB ? 'GB' : 'MB'
  end

  def data_limit_value
    bytes = object.data_limit_bytes
    return nil if bytes.blank?
    divisor = bytes >= BYTES_PER_GB ? BYTES_PER_GB : BYTES_PER_MB
    v = (bytes.to_f / divisor).round(2)
    v == v.to_i ? v.to_i : v
  end

  def data_limit_label
    return 'Unlimited' if object.data_limit_bytes.blank?
    "#{data_limit_value} #{data_limit_unit}"
  end
end




