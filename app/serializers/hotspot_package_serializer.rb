class HotspotPackageSerializer < ActiveModel::Serializer
  attributes :id, :name, :price, :download_limit, :upload_limit, :account_id, :tx_rate_limit, :rx_rate_limit, 
  :validity_period_units, :download_burst_limit, :upload_burst_limit, :validity, :speed, :valid,
  :valid_from, :valid_until, :weekdays, :shared_users




  def name
    object.speed == 'M/M' && "Unlimited #{object.name}"
  end


  
  
  def valid_from
    object.valid_from.strftime('%I:%M %p') if object.valid_from.present?
  end

  def valid_until
    object.valid_until.strftime('%I:%M %p') if object.valid_until.present?
  end

  def speed
    "#{self.object.upload_limit}M/#{self.object.download_limit}M" if self.object.upload_limit && self.object.download_limit
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
