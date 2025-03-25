class NaSerializer < ActiveModel::Serializer
  attributes :id, :shortname, :nasname, :ipaddr, :secret
  def ipaddr
    
    object.nasname 
  end

  
end