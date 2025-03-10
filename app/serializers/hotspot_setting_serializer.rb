class HotspotSettingSerializer < ActiveModel::Serializer
  attributes :id, :phone_number, :hotspot_name, :hotspot_info, :hotspot_banner, :account_id,
  :email

  
end
