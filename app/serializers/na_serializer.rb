class NaSerializer < ActiveModel::Serializer
  attributes :id, :name, :shortname, :nasname, :ipaddr, :secret, :nas_type
  def ipaddr
    
    object.nasname 
  end

  
end