class ZoneSerializer < ActiveModel::Serializer

  require 'securerandom'

  attributes :id, :name, :zone_code


  # def zone_code
  #   self.object.zone_code = SecureRandom.alphanumeric(6) 
    

  # end
end






