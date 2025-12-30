class HotspotCustomizationSerializer < ActiveModel::Serializer
  attributes :id, :customize_template_and_package_per_location, 
  :enable_autologin,
  :account_id
end




