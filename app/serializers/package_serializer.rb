class PackageSerializer < ActiveModel::Serializer
  attributes :id, :name, :price, :download_limit, :upload_limit, :account_id, :tx_rate_limit,
   :rx_rate_limit, :validity_period_units, :download_burst_limit, :upload_burst_limit, :validity, :speed, :validity,
    :valid, :ip_pool, :package

    
   def speed
    "#{self.object.upload_limit}M/#{self.object.download_limit}M"
  end


  def package
    "#{object.download_limit} Mbps"
  end
  
  # def valid
  #   self.object.validity_period_units == 'days' ? "#{self.object.validity}days" : "#{self.object.validity}hour"
  # end
  # 
  #
  def valid
    case self.object.validity_period_units
    when 'days'
      "#{self.object.validity} days"
    when 'hour'
      "#{self.object.validity} hour"
    when 'minutes'
      "#{self.object.validity} minutes"
    else
      nil # Return nil if no match is found
    end
  end
end


