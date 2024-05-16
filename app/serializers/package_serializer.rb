class PackageSerializer < ActiveModel::Serializer
  attributes :id, :name, :price, :download_limit, :upload_limit, :account_id, :tx_rate_limit,
   :rx_rate_limit, :validity_period_units, :download_burst_limit, :upload_burst_limit, :validity, :speed, :validity,
    :valid

    
   def speed
    "#{self.object.upload_limit}M/#{self.object.download_limit}M"
  end

  def valid
    self.object.validity_period_units == 'days' ? "#{self.object.validity}days" : "#{self.object.validity}hour"
  end
end
